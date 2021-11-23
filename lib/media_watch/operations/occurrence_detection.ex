defmodule MediaWatch.Analysis.OccurrenceDetectionOperation do
  alias Ecto.Multi
  alias MediaWatch.{Repo, OperationWithRetry, Catalog}
  alias MediaWatch.Parsing.Slice
  alias MediaWatch.Analysis.{Recurrent, ShowOccurrence, SliceUsage}
  alias __MODULE__
  @behaviour OperationWithRetry
  @errors_with_retry [:database_busy]
  @max_db_retries 20

  @type error_reason :: :max_db_retries
  @type t :: %OccurrenceDetectionOperation{
          slice: Slice.t(),
          module: atom(),
          show_id: integer() | nil,
          slice_date: DateTime.t() | nil,
          time_slot: Recurrent.time_slot() | nil,
          airing_time: DateTime.t() | nil,
          slice_usage_done?: boolean(),
          multi: Multi.t() | nil,
          retry_strategy: OperationWithRetry.retry_strategy_fun(),
          retries: any()
        }

  @derive {Inspect, except: [:slice, :retry_strategy]}
  defstruct [
    :slice,
    :module,
    :show_id,
    :slice_date,
    :time_slot,
    :airing_time,
    :multi,
    :retries,
    :retry_strategy,
    slice_usage_done?: false
  ]

  @spec new(Slice.t(), atom()) :: OccurrenceDetectionOperation.t()
  def new(slice = %Slice{}, module),
    do:
      %OccurrenceDetectionOperation{
        slice: slice |> Repo.preload(Slice.preloads()),
        module: module
      }
      |> set_retry_strategy(&default_strategy/2)
      |> OperationWithRetry.init_retries(@errors_with_retry)

  defdelegate set_retry_strategy(operation, retry_fun), to: OperationWithRetry

  @impl OperationWithRetry
  def run(operation = %OccurrenceDetectionOperation{slice_date: nil}),
    do: operation |> get_slice_info() |> run()

  def run(operation = %OccurrenceDetectionOperation{airing_time: nil}),
    do: operation |> search_matching_slot() |> run()

  def run(operation = %OccurrenceDetectionOperation{multi: nil}),
    do: operation |> create_multi() |> run()

  def run(operation = %OccurrenceDetectionOperation{multi: %Multi{}}),
    do: operation |> run_multi()

  def run(ok = {status, _}) when status in [:ok, :already], do: ok
  def run(e = {:error, _}), do: e

  defp get_slice_info(operation = %OccurrenceDetectionOperation{slice: slice}) do
    with show_id when not is_nil(show_id) <- Catalog.show_id_from_source_id(slice.source_id),
         {:ok, date} <- Slice.extract_date(slice) do
      %{operation | slice_date: date, show_id: show_id}
    else
      :error -> {:error, :no_date}
      nil -> {:error, :no_show}
    end
  end

  defp search_matching_slot(
         operation = %OccurrenceDetectionOperation{module: recurrent, slice_date: date}
       ) do
    with time_slot <- date |> Recurrent.get_time_slot(recurrent),
         airing_time when is_struct(airing_time, DateTime) <-
           Recurrent.get_airing_time(date, recurrent) do
      %{operation | airing_time: airing_time, time_slot: time_slot}
    else
      e = {:error, :no_run_within_slot} -> e
    end
  end

  defp create_multi(
         operation = %OccurrenceDetectionOperation{
           slice: %{id: slice_id},
           show_id: show_id,
           airing_time: airing_time,
           time_slot: {slot_start, slot_end}
         }
       ) do
    occurrence_attrs = %{
      show_id: show_id,
      airing_time: airing_time,
      slot_start: slot_start,
      slot_end: slot_end
    }

    slice_usage_attrs = %{slice_id: slice_id}

    multi =
      Multi.new()
      |> Multi.run(
        :create_or_get_occurrence,
        &create_or_get_occurrence_step(occurrence_attrs, &1, &2)
      )
      |> Multi.run(:mark_slice_as_used, &mark_slice_as_used_step(slice_usage_attrs, &1, &2))

    %{operation | multi: multi}
  end

  defp create_or_get_occurrence_step(occurrence_attrs, repo, _changes) do
    case occurrence_attrs
         |> ShowOccurrence.create_changeset()
         |> repo.insert()
         |> ShowOccurrence.explain_error(repo) do
      ok = {:ok, _} -> ok
      {:error, unique = {:unique, _}} -> {:ok, unique}
      e = {:error, _} -> e
    end
  end

  defp mark_slice_as_used_step(slice_usage_attrs, repo, %{create_or_get_occurrence: res}) do
    occurrence_id =
      case res do
        {:unique, occ} -> occ.id
        occ -> occ.id
      end

    case slice_usage_attrs
         |> Map.put(:show_occurrence_id, occurrence_id)
         |> SliceUsage.create_changeset()
         |> repo.insert()
         |> SliceUsage.explain_error() do
      ok = {:ok, _} -> ok
      {:error, :unique} -> {:ok, :unique}
      e = {:error, _} -> e
    end
  end

  defp run_multi(operation = %OccurrenceDetectionOperation{multi: multi}) do
    case multi |> Repo.safe_transaction() do
      {:ok, %{create_or_get_occurrence: {:unique, occ}}} -> {:already, occ}
      {:ok, %{create_or_get_occurrence: occ}} -> {:ok, occ}
      {:error, e = :database_busy} -> OperationWithRetry.maybe_retry(operation, e)
      e = {:error, _, _, _} -> e
    end
  end

  defp default_strategy(:database_busy, retries) when retries < @max_db_retries, do: :retry
  defp default_strategy(_, _), do: :abort
end
