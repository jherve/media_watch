defmodule MediaWatch.Snapshots do
  import Ecto.Query
  alias MediaWatch.{Catalog, Repo}
  alias MediaWatch.Snapshots.Snapshot

  def get_snapshots(source_ids),
    do:
      from(s in Snapshot,
        where: s.source_id in ^source_ids,
        preload: [:xml],
        select: {s.source_id, s}
      )
      |> Repo.all()

  def do_all_snapshots(), do: Catalog.all() |> Enum.each(&do_snapshots/1)

  def do_snapshots(module), do: module.do_snapshots()
end
