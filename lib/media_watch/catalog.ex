defmodule MediaWatch.Catalog do
  import Ecto.Query
  alias MediaWatch.Repo
  alias MediaWatch.Catalog.{Item, Source, Show}
  @source_preloads [:rss_feed]
  @preloads [:channels, :show, sources: @source_preloads]
  @config Application.compile_env(:media_watch, __MODULE__)

  def select_all_sources(),
    do: from(s in Source, preload: ^@source_preloads)

  def select_sources(item_id),
    do: from(s in Source, where: s.item_id == ^item_id, preload: ^@source_preloads)

  def list_all(), do: Item |> Repo.all() |> Repo.preload(@preloads)
  def get(id), do: Item |> Repo.get(id) |> Repo.preload(@preloads)

  def get_source(id), do: Source |> Repo.get(id) |> Repo.preload(@source_preloads)

  def get_item_id(source_id) do
    from(s in Source, where: s.id == ^source_id, select: s.item_id) |> Repo.one()
  end

  def get_show_id(source_id) do
    from(s in Show,
      join: i in Item,
      on: i.id == s.id,
      join: source in Source,
      on: source.item_id == i.id,
      where: source.id == ^source_id,
      select: s.id
    )
    |> Repo.one()
  end

  def try_to_insert_all_channels(),
    do: all_channel_modules() |> Enum.each(& &1.insert())

  def all_channel_modules(), do: @config[:channels] |> Keyword.keys()

  def all(), do: @config[:items] |> Keyword.keys()

  def module_from_show_id(show_id),
    do:
      from(s in Show, join: i in Item, on: i.id == s.id, where: s.id == ^show_id, select: i.module)
      |> Repo.one()

  def module_from_source_id(source_id),
    do:
      from(s in Source,
        join: i in Item,
        on: i.id == s.item_id,
        where: s.id == ^source_id,
        select: i.module
      )
      |> Repo.one()
end
