defmodule MediaWatch.Parsing do
  import Ecto.Query
  alias MediaWatch.Repo
  alias MediaWatch.Snapshots.Snapshot
  alias MediaWatch.Parsing.{ParsedSnapshot, Slice}
  @parsed_preloads [:xml, :source]

  def get_parsed(source_ids) when is_list(source_ids),
    do:
      from(p in ParsedSnapshot,
        join: s in Snapshot,
        on: s.id == p.snapshot_id,
        where: s.source_id in ^source_ids,
        select: {s.source_id, p}
      )
      |> Repo.all()

  def get_slices(source_ids) when is_list(source_ids),
    do:
      from(s in Slice, where: s.source_id in ^source_ids, select: {s.source_id, s})
      |> Repo.all()

  def get(id), do: ParsedSnapshot |> Repo.get(id) |> Repo.preload(snapshot: @parsed_preloads)

  def get_all(), do: ParsedSnapshot |> Repo.all() |> Repo.preload(snapshot: @parsed_preloads)
end
