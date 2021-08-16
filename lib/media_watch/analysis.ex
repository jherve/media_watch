defmodule MediaWatch.Analysis do
  import Ecto.Query
  alias MediaWatch.Repo
  alias MediaWatch.Parsing
  alias MediaWatch.Parsing.ParsedSnapshot
  alias MediaWatch.Snapshots.Snapshot
  alias MediaWatch.Catalog.Source
  alias MediaWatch.Analysis.{SlicingJob, Facet}

  def get_jobs(), do: Parsing.get_all() |> Enum.map(&%SlicingJob{snapshot: &1})

  def run_jobs(jobs) when is_list(jobs), do: jobs |> Enum.map(&SlicingJob.run/1)

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
