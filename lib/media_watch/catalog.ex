defmodule MediaWatch.Catalog do
  import Ecto.Query
  alias MediaWatch.Repo
  alias MediaWatch.Catalog.{Item, Source}
  @source_preloads [:rss_feed]
  @preloads [:channels, :show, sources: @source_preloads]

  def get_all_sources(), do: list_all() |> Enum.flat_map(& &1.sources)

  def select_sources(item_id),
    do: from(s in Source, where: s.item_id == ^item_id, preload: ^@source_preloads)

  def get_source_ids(item_id),
    do: from(s in Source, where: s.item_id == ^item_id, select: s.id) |> Repo.all()

  def list_all(), do: Item |> Repo.all() |> Repo.preload(@preloads)
  def get(id), do: Item |> Repo.get(id) |> Repo.preload(@preloads)
end
