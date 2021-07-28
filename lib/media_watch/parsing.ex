defmodule MediaWatch.Parsing do
  alias MediaWatch.Snapshots
  alias MediaWatch.Parsing.Job

  def get_jobs(), do: Snapshots.get_all_snapshots() |> Enum.map(&%Job{snapshot: &1})

  def run_jobs(jobs) when is_list(jobs), do: jobs |> Enum.map(&Job.run/1)
end
