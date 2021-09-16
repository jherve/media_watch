defmodule MediaWatch.Analysis do
  import Ecto.Query
  alias Ecto.Multi
  alias MediaWatch.Repo
  alias MediaWatch.Parsing.ParsedSnapshot
  alias MediaWatch.Snapshots.Snapshot
  alias MediaWatch.Catalog.Source
  alias MediaWatch.Analysis.Facet

  def do_slicing(snap = %ParsedSnapshot{}),
    do:
      with(
        cs_list when is_list(cs_list) <- ParsedSnapshot.slice(snap),
        multi <-
          cs_list
          |> Enum.with_index()
          |> Enum.reduce(Multi.new(), fn {cs, idx}, multi ->
            multi |> Multi.insert({:facet, idx}, cs)
          end),
        do: multi |> Repo.transaction()
      )

  def get_all_facets(item_id) do
    from(f in Facet,
      join: ps in ParsedSnapshot,
      on: ps.id == f.parsed_snapshot_id,
      join: snap in Snapshot,
      on: snap.id == ps.id,
      join: s in Source,
      on: snap.id == s.id,
      where: s.item_id == ^item_id,
      preload: [:show_occurrence, :description]
    )
    |> Repo.all()
  end
end
