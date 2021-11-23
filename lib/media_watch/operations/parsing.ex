defmodule MediaWatch.Parsing.ParsingOperation do
  alias MediaWatch.{Repo, OperationWithRetry}
  alias MediaWatch.Snapshots.Snapshot
  alias MediaWatch.Parsing.Parsable
  alias __MODULE__
  @behaviour OperationWithRetry
  @errors_with_retry [:database_busy]
  @max_db_retries 20

  @type error_reason :: :max_db_retries
  @type t :: %ParsingOperation{
          snapshot: Snapshot.t(),
          module: atom(),
          parsed_snapshot_cs: Ecto.Changeset.t(),
          retry_strategy: OperationWithRetry.retry_strategy_fun(),
          retries: any()
        }

  @derive {Inspect, except: [:snapshot, :parsed_snapshot_cs]}
  defstruct [:snapshot, :module, :parsed_snapshot_cs, :retries, :retry_strategy]

  @spec new(Snapshot.t(), atom()) :: ParsingOperation.t()
  def new(snapshot = %Snapshot{}, module),
    do:
      %ParsingOperation{snapshot: snapshot |> Repo.preload(Snapshot.preloads()), module: module}
      |> set_retry_strategy(&default_strategy/2)
      |> OperationWithRetry.init_retries(@errors_with_retry)

  defdelegate set_retry_strategy(operation, retry_fun), to: OperationWithRetry

  @impl OperationWithRetry
  def run(
        operation = %ParsingOperation{snapshot: snapshot, module: module, parsed_snapshot_cs: nil}
      ) do
    with {:ok, cs} <- Parsable.parse(snapshot, module),
         do: %{operation | parsed_snapshot_cs: cs} |> run
  end

  def run(operation = %ParsingOperation{parsed_snapshot_cs: cs}) do
    case cs |> Repo.safe_insert() do
      ok = {:ok, _snap} -> ok
      {:error, :database_busy} -> operation |> OperationWithRetry.maybe_retry(:database_busy)
      e = {:error, %Ecto.Changeset{}} -> e
    end
  end

  defp default_strategy(:database_busy, retries) when retries < @max_db_retries, do: :retry
  defp default_strategy(_, _), do: :abort
end
