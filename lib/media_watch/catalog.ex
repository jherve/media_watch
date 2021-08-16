defmodule MediaWatch.Catalog do
  alias MediaWatch.Repo
  alias MediaWatch.Catalog.Item
  @preloads [:show, sources: :rss_feed]

  def get_all_sources(), do: list_all() |> Enum.flat_map(& &1.sources)

  def list_all(), do: Item |> Repo.all() |> Repo.preload(@preloads)
  def get(id), do: Item |> Repo.get(id) |> Repo.preload(@preloads)
end
