defmodule MediaWatch.Catalog do
  import Ecto.Query
  alias MediaWatch.Repo
  alias MediaWatch.Catalog.{Item, Source, Show, Channel}
  @source_preloads [:rss_feed]
  @preloads [:channels, :show, sources: @source_preloads]

  def select_all_sources(),
    do: from(s in Source, preload: ^@source_preloads)

  def select_sources(item_id),
    do: from(s in Source, where: s.item_id == ^item_id, preload: ^@source_preloads)

  def list_all(), do: Item |> Repo.all() |> Repo.preload(@preloads)
  def get(id), do: Item |> Repo.get(id) |> Repo.preload(@preloads)

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
    do: all_channel_modules() |> Enum.each(& &1.insert(Repo))

  def all_channel_modules(),
    do: [
      Channel.FranceInter,
      Channel.FranceCulture,
      Channel.FranceInfo,
      Channel.RTL,
      Channel.RMC
    ]

  def all(),
    do: [
      Item.Le8h30FranceInfo,
      Item.BourdinDirect,
      Item.Invite7h50,
      Item.Invite8h20,
      Item.InviteDesMatins,
      Item.InviteRTL,
      Item.InviteRTLSoir,
      Item.LaGrandeTableIdees
    ]
end
