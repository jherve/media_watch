defmodule MediaWatch.Snapshots do
  alias MediaWatch.Catalog
  alias MediaWatch.Catalog.Source

  def get_jobs(),
    do:
      Catalog.list_all()
      |> Enum.flat_map(& &1.sources)
      |> Enum.map(&{&1.item_id, &1})

  def run_jobs(jobs) when is_list(jobs) do
    jobs
    |> Enum.map(fn {item_id, source} -> {item_id, Source.get_snapshot(source)} end)
  end
end
