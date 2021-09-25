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

  def all_channels(),
    do: %{
      france_inter: %{name: "France Inter", url: "https://www.franceinter.fr"},
      france_culture: %{name: "France Culture", url: "https://www.franceculture.fr"},
      france_info: %{name: "France Info", url: "https://www.francetvinfo.fr"},
      rmc: %{name: "RMC", url: "https://rmc.bfmtv.com/"},
      rtl: %{name: "RTL", url: "https://www.rtl.fr"}
    }

  def try_to_insert_all_channels(),
    do: all_channels() |> Map.values() |> Enum.each(&(&1 |> Channel.changeset() |> Repo.insert()))

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
