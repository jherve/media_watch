defmodule MediaWatch.Snapshots do
  alias MediaWatch.Catalog
  alias MediaWatch.Catalog.Source

  def get_jobs(), do: Catalog.get_all_sources()

  def run_jobs(jobs) when is_list(jobs) do
    jobs
    |> Enum.map(&Source.get_snapshot/1)
  end
end
