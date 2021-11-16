defmodule MediaWatch.Snapshots.SnapshotOperation do
  alias MediaWatch.{Snapshots, Repo, OperationWithRetry}
  alias MediaWatch.Catalog.Source
  alias __MODULE__
  @behaviour OperationWithRetry

  @max_snap_retries 5
  @max_db_retries 20
  @errors_with_retry [:snap_timeout, :database_busy]

  @opaque t :: %SnapshotOperation{
            source: Source.t(),
            snapshot_cs: Ecto.Changeset.t(),
            retry_strategy: OperationWithRetry.retry_strategy_fun(),
            retries: map()
          }

  @derive {Inspect, except: [:source, :snapshot_cs, :retry_strategy]}
  defstruct [:source, :snapshot_cs, :retry_strategy, :retries]

  @spec new(Source.t()) :: SnapshotOperation.t()
  def new(source = %Source{}),
    do:
      %SnapshotOperation{source: source |> Repo.preload(Source.preloads())}
      |> set_retry_strategy(&default_strategy/2)
      |> OperationWithRetry.init_retries(@errors_with_retry)

  defdelegate set_retry_strategy(operation, retry_fun), to: OperationWithRetry

  @impl OperationWithRetry
  def run(operation = %SnapshotOperation{source: source, snapshot_cs: nil}) do
    case Snapshots.take_snapshot(source) do
      {:ok, cs} -> %{operation | snapshot_cs: cs} |> run
      {:error, %{reason: :timeout}} -> operation |> OperationWithRetry.maybe_retry(:snap_timeout)
    end
  end

  def run(operation = %SnapshotOperation{snapshot_cs: cs}) do
    case cs |> Repo.safe_insert() do
      ok = {:ok, _snap} -> ok
      {:error, :database_busy} -> operation |> OperationWithRetry.maybe_retry(:database_busy)
      e = {:error, %Ecto.Changeset{}} -> e
    end
  end

  defp default_strategy(:snap_timeout, retries) when retries < @max_snap_retries, do: :retry
  defp default_strategy(:database_busy, retries) when retries < @max_db_retries, do: :retry
  defp default_strategy(_, _), do: :abort
end
