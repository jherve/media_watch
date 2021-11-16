defmodule MediaWatch.Catalog do
  import Ecto.Query
  alias MediaWatch.Repo
  alias MediaWatch.Catalog.{Item, Channel, Source, Show, Person}
  @source_preloads [:rss_feed, :web_index_page]

  def all_items(), do: Item |> Repo.all()

  def get_item_from_module(module) when is_atom(module),
    do:
      from(i in Item,
        where: i.module == ^module,
        preload: [:channels, :show, sources: ^@source_preloads]
      )
      |> Repo.one()

  def all_channels(), do: Channel |> Repo.all()

  def get_source(id), do: Source |> Repo.get(id) |> Repo.preload(@source_preloads)

  def get_person(id), do: Person |> Repo.get(id)

  def list_persons(), do: from(p in Person, order_by: p.label) |> Repo.all()

  def module_from_source_id(source_id),
    do:
      from(s in Source,
        join: i in Item,
        on: i.id == s.item_id,
        where: s.id == ^source_id,
        select: i.module
      )
      |> Repo.one()

  def show_id_from_source_id(source_id),
    do:
      from(s in Show,
        join: i in Item,
        on: i.id == s.id,
        join: so in Source,
        on: so.item_id == i.id,
        where: so.id == ^source_id,
        select: s.id
      )
      |> Repo.one()

  def item_id_from_source_id(source_id),
    do:
      from(so in Source, where: so.id == ^source_id, select: so.item_id)
      |> Repo.one()
end
