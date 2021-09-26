defmodule MediaWatch.Snapshots do
  alias MediaWatch.Catalog
  alias MediaWatch.Catalog.ItemTask

  def do_all_snapshots(), do: Catalog.all() |> Enum.each(&do_snapshots/1)

  defdelegate do_snapshots(module), to: ItemTask
end
