defmodule MediaWatch.Snapshots do
  alias MediaWatch.Repo
  alias MediaWatch.Catalog.Source
  alias MediaWatch.Snapshots.{Snapshot, Snapshotter}

  def get_snapshot(id), do: Snapshot |> Repo.get(id) |> Repo.preload(:xml)

  def get_all_snapshots(), do: Snapshot |> Repo.all() |> Repo.preload(:xml)

  def run_snapshot_job(source = %Source{}),
    do: with({:ok, cs} <- Source.make_snapshot(source), do: cs |> Repo.insert())

  defdelegate do_snapshots(id), to: Snapshotter
end
