defmodule MediaWatch.Catalog do
  import Ecto.Query
  alias MediaWatch.Repo
  alias MediaWatch.Catalog.{Item, Source, Person}
  @source_preloads [:rss_feed, :web_index_page]
  @config Application.compile_env(:media_watch, __MODULE__)

  def get_source(id), do: Source |> Repo.get(id) |> Repo.preload(@source_preloads)

  def get_person(id), do: Person |> Repo.get(id)

  def list_persons(), do: from(p in Person, order_by: p.label) |> Repo.all()

  def try_to_insert_all_channels() do
    all_channel_modules() |> Enum.each(& &1.insert())
  rescue
    e in Exqlite.Error -> {:error, e}
  end

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
