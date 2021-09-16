defmodule MediaWatch.Parsing do
  alias MediaWatch.Repo
  alias MediaWatch.Snapshots
  alias MediaWatch.Parsing.{Job, ParsedSnapshot}
  @parsed_preloads [:xml, :source]

  def get_jobs(), do: Snapshots.get_all_snapshots() |> Enum.map(&%Job{snapshot: &1})

  def run_jobs(jobs) when is_list(jobs), do: jobs |> Enum.map(&Job.run/1)

  def get(id), do: ParsedSnapshot |> Repo.get(id) |> Repo.preload(snapshot: @parsed_preloads)
  def get_all(), do: ParsedSnapshot |> Repo.all() |> Repo.preload(snapshot: @parsed_preloads)
end
