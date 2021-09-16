defmodule MediaWatch.Snapshots do
  alias MediaWatch.Repo
  alias MediaWatch.Catalog
  alias MediaWatch.Snapshots.{Job, Snapshot}

  def get_jobs(), do: Catalog.get_all_sources() |> Enum.map(&%Job{source: &1})

  def run_jobs(jobs) when is_list(jobs), do: jobs |> Enum.map(&Job.run/1)

  def get_snapshot(id), do: Snapshot |> Repo.get(id) |> Repo.preload(:xml)

  def get_all_snapshots(), do: Snapshot |> Repo.all() |> Repo.preload(:xml)
end
