defmodule MediaWatch.Snapshots do
  alias MediaWatch.Snapshots.{SnapshotsServer, SnapshotPipeline}
  alias MediaWatch.Catalog.{ItemWorker, Source}

  def do_all_snapshots(), do: MediaWatchInventory.all() |> Enum.each(&do_snapshots/1)

  def do_snapshots(module), do: ItemWorker.do_snapshots(module)

  @spec take_snapshot(Source.t()) :: {:ok, Ecto.Changeset.t()} | {:error, any()}
  def take_snapshot(source), do: Source.take_snapshot(source)

  def snapshot(module, source), do: SnapshotsServer.snapshot(module, source)

  def run_snapshot_pipeline(source, module),
    do: SnapshotPipeline.new(source, module) |> SnapshotPipeline.run()
end
