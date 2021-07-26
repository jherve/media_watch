defmodule MediaWatch.Snapshots do
  alias MediaWatch.Catalog
  alias MediaWatch.Snapshots.Job

  def get_jobs(), do: Catalog.get_all_sources() |> Enum.map(&%Job{source: &1})

  def run_jobs(jobs) when is_list(jobs), do: jobs |> Enum.map(&Job.run/1)
end
