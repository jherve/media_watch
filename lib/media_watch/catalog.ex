defmodule MediaWatch.Catalog do
  import Ecto.Query
  alias MediaWatch.Repo
  alias MediaWatch.Catalog.{Item, Source}
  @source_preloads [:rss_feed]
  @config Application.compile_env(:media_watch, __MODULE__)

  def get_source(id), do: Source |> Repo.get(id) |> Repo.preload(@source_preloads)

  def try_to_insert_all_channels(),
    do: all_channel_modules() |> Enum.each(& &1.insert())

  def all_channel_modules(), do: @config[:channels] |> Keyword.keys()

  def all(), do: @config[:items] |> Keyword.keys()

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
