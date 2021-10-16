defmodule MediaWatch.Snapshots do
  import Ecto.Query
  alias MediaWatch.{Catalog, Repo}
  alias MediaWatch.Snapshots.Snapshot
  alias MediaWatch.Catalog.ItemWorker

  def get_snapshots(source_id),
    do:
      from(s in Snapshot, where: s.source_id == ^source_id, preload: [:xml])
      |> Repo.all()

  def do_all_snapshots(), do: Catalog.all() |> Enum.each(&do_snapshots/1)

  def do_snapshots(module), do: ItemWorker.do_snapshots(module)
end
