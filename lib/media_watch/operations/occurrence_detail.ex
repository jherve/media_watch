defmodule MediaWatch.Analysis.OccurrenceDetailOperation do
  alias MediaWatch.{Repo, OperationWithRetry}
  alias MediaWatch.Parsing.Slice
  alias MediaWatch.Analysis.ShowOccurrence
  alias MediaWatch.Analysis.ShowOccurrence.Detail
  alias __MODULE__
  @behaviour OperationWithRetry
  @errors_with_retry [:database_busy]
  @max_db_retries 20
  @preloads [:detail, slices: Slice.preloads()]

  @type error_reason :: :max_db_retries
  @type t :: %OccurrenceDetailOperation{
          occurrence: ShowOccurrence.t(),
          slice: Slice.t(),
          detail: Detail.t() | nil,
          detail_created?: boolean() | nil,
          retry_strategy: OperationWithRetry.retry_strategy_fun(),
          retries: any()
        }

  @derive {Inspect, except: [:occurrence, :slice]}
  defstruct [
    :occurrence,
    :slice,
    :detail_cs,
    :detail,
    :detail_created?,
    :retries,
    :retry_strategy
  ]

  @spec new(ShowOccurrence.t(), Slice.t()) :: OccurrenceDetailOperation.t()
  def new(occurrence = %ShowOccurrence{}, slice = %Slice{}),
    do:
      %OccurrenceDetailOperation{
        occurrence: occurrence |> Repo.preload(@preloads),
        slice: slice |> Repo.preload(Slice.preloads())
      }
      |> set_retry_strategy(&default_strategy/2)
      |> OperationWithRetry.init_retries(@errors_with_retry)

  defdelegate set_retry_strategy(operation, retry_fun), to: OperationWithRetry

  @impl OperationWithRetry
  def run(
        operation = %OccurrenceDetailOperation{
          occurrence: occurrence,
          slice: slice,
          detail_cs: nil
        }
      ) do
    %{
      operation
      | detail_cs:
          slice |> Detail.attrs_from_slice() |> Map.put(:id, occurrence.id) |> Detail.changeset()
    }
    |> run()
  end

  def run(operation = %OccurrenceDetailOperation{detail_cs: cs, detail: nil}) do
    case cs |> Repo.safe_insert() |> Detail.explain_create_error(Repo) do
      {:ok, detail} ->
        %{operation | detail: detail, detail_created?: true} |> run()

      {:error, e = :database_busy} ->
        OperationWithRetry.maybe_retry(operation, e)

      {:error, {:unique, existing}} ->
        %{operation | detail: existing, detail_created?: false} |> run()

      e = {:error, _} ->
        e
    end
  end

  def run(%OccurrenceDetailOperation{detail: detail, detail_created?: true}) do
    {:ok, detail}
  end

  def run(operation = %OccurrenceDetailOperation{detail: detail, detail_created?: false}) do
    case Detail.changeset(detail, %{}) |> Repo.safe_update() do
      {:ok, detail} -> {:updated, detail}
      {:error, e = :database_busy} -> OperationWithRetry.maybe_retry(operation, e)
      e = {:error, _} -> e
    end
  end

  defp default_strategy(:database_busy, retries) when retries < @max_db_retries, do: :retry
  defp default_strategy(_, _), do: :abort
end
