defmodule MediaWatch.Analysis.OccurrenceDetectionOperation do
  alias MediaWatch.{Repo, OperationWithRetry, Catalog}
  alias MediaWatch.Parsing.Slice
  alias MediaWatch.Analysis.{Recurrent, ShowOccurrence, SliceUsage}
  alias __MODULE__
  @behaviour OperationWithRetry
  @errors_with_retry [:database_busy]
  @max_db_retries 20

  @type error_reason :: :max_db_retries
  @opaque t :: %OccurrenceDetectionOperation{
            slice: Slice.t(),
            slice_type: atom(),
            module: atom(),
            show_id: integer() | nil,
            slice_date: DateTime.t() | nil,
            time_slot: Recurrent.time_slot() | nil,
            airing_time: DateTime.t() | nil,
            occurrence: ShowOccurrence.t() | nil,
            occurrence_created?: boolean() | nil,
            slice_usage_done?: boolean(),
            retry_strategy: OperationWithRetry.retry_strategy_fun(),
            retries: any()
          }

  @derive {Inspect, except: [:slice, :retry_strategy]}
  defstruct [
    :slice,
    :slice_type,
    :module,
    :show_id,
    :slice_date,
    :time_slot,
    :airing_time,
    :occurrence,
    :occurrence_created?,
    :retries,
    :retry_strategy,
    slice_usage_done?: false
  ]

  @spec new(Slice.t(), atom(), atom()) :: OccurrenceDetectionOperation.t()
  def new(slice = %Slice{}, slice_type, module),
    do:
      %OccurrenceDetectionOperation{
        slice: slice |> Repo.preload(Slice.preloads()),
        slice_type: slice_type,
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

  def run(operation = %OccurrenceDetectionOperation{occurrence: nil}),
    do: operation |> create_or_get_occurrence() |> run()

  def run(operation = %OccurrenceDetectionOperation{slice_usage_done?: false}),
    do: operation |> mark_slice_as_used() |> run()

  def run(operation = %OccurrenceDetectionOperation{slice_usage_done?: true}),
    do: operation |> do_return()

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

  defp create_or_get_occurrence(
         operation = %OccurrenceDetectionOperation{
           show_id: show_id,
           airing_time: airing_time,
           time_slot: {slot_start, slot_end}
         }
       ) do
    case %{show_id: show_id, airing_time: airing_time, slot_start: slot_start, slot_end: slot_end}
         |> ShowOccurrence.create_changeset()
         |> Repo.safe_insert()
         |> ShowOccurrence.explain_error(Repo) do
      {:ok, occ} -> %{operation | occurrence: occ, occurrence_created?: true}
      {:error, {:unique, occ}} -> %{operation | occurrence: occ, occurrence_created?: false}
      {:error, e = :database_busy} -> OperationWithRetry.maybe_retry(operation, e)
      e = {:error, _} -> e
    end
  end

  defp mark_slice_as_used(
         operation = %OccurrenceDetectionOperation{
           slice: %{id: slice_id},
           occurrence: %{id: occurrence_id},
           slice_type: type
         }
       ) do
    case %{slice_id: slice_id, show_occurrence_id: occurrence_id, type: type}
         |> SliceUsage.create_changeset()
         |> Repo.safe_insert()
         |> SliceUsage.explain_error() do
      {:ok, _} -> %{operation | slice_usage_done?: true}
      {:error, :unique} -> %{operation | slice_usage_done?: true}
      {:error, e = :database_busy} -> OperationWithRetry.maybe_retry(operation, e)
      e = {:error, _} -> e
    end
  end

  defp do_return(%OccurrenceDetectionOperation{occurrence: occurrence, occurrence_created?: true}),
    do: {:ok, occurrence}

  defp do_return(%OccurrenceDetectionOperation{occurrence: occurrence, occurrence_created?: false}),
       do: {:already, occurrence}

  defp default_strategy(:database_busy, retries) when retries < @max_db_retries, do: :retry
  defp default_strategy(_, _), do: :abort
end
