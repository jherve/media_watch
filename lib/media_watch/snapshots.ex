defmodule MediaWatch.Snapshots do
  alias MediaWatch.Snapshots.{SnapshotOperation, SnapshotPipeline}
  alias MediaWatch.Catalog.{ItemWorker, Source}

  def do_all_snapshots(), do: MediaWatchInventory.all() |> Enum.each(&do_snapshots/1)

  def do_snapshots(module), do: ItemWorker.do_snapshots(module)

  @spec take_snapshot(Source.t()) :: {:ok, Ecto.Changeset.t()} | {:error, any()}
  def take_snapshot(source), do: Source.take_snapshot(source)

  def snapshot(_module, source),
    do:
      SnapshotOperation.new(source)
      |> SnapshotOperation.set_retry_strategy(fn
        :snap_timeout, nb_retries -> if nb_retries < 5, do: :retry, else: :abort
        :database_busy, _ -> :retry_exp
      end)
      |> SnapshotOperation.run()

  def run_snapshot_pipeline(source, module),
    do: SnapshotPipeline.new(source, module) |> SnapshotPipeline.run()
end
