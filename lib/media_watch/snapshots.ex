defmodule MediaWatch.Snapshots do
  alias MediaWatch.Catalog
  alias MediaWatch.Snapshots.Strategy

  def get_jobs(),
    do:
      Catalog.list_all()
      |> Enum.flat_map(& &1.strategies)
      |> Enum.map(&{&1.watched_item_id, Strategy.get_actual_strategy(&1)})

  def run_jobs(jobs) when is_list(jobs) do
    jobs
    |> Enum.map(fn {item_id, strategy = %struct{}} -> {item_id, struct.get_snapshot(strategy)} end)
  end
end
