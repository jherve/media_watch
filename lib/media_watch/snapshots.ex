defmodule MediaWatch.Snapshots do
  alias MediaWatch.Repo
  alias MediaWatch.Catalog.Source
  alias MediaWatch.Snapshots.Snapshotter

  def run_snapshot_job(source = %Source{}),
    do: with({:ok, cs} <- Source.make_snapshot(source), do: cs |> Repo.insert())

  defdelegate do_snapshots(id), to: Snapshotter
  defdelegate do_all_snapshots(), to: Snapshotter
end
