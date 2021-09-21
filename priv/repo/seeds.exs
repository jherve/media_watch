# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     MediaWatch.Repo.insert!(%MediaWatch.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

defmodule Utils do
  require Logger
  import Ecto.Query
  alias Ecto.Multi
  alias MediaWatch.Catalog.{Channel, ChannelItem, Item, Show}

  def get_or_insert(multi, map) when is_map(map) do
    map
    |> Enum.reduce(multi, fn
      {name, {arg1, arg2}}, multi -> multi |> get_or_insert(name, arg1, arg2)
      {name, v}, multi -> multi |> get_or_insert(name, v)
    end)
  end

  def get_or_insert(multi, name, channel_cs = %Ecto.Changeset{data: data})
      when is_struct(data, Channel),
      do:
        multi
        |> Multi.run(
          name,
          fn repo, _ ->
            name = channel_cs |> Ecto.Changeset.fetch_field!(:name)

            case Channel |> repo.get_by(name: name) do
              nil -> channel_cs |> repo.insert
              db_channel -> {:ok, db_channel}
            end
          end
        )

  def get_or_insert(multi, name, item_cs = %Ecto.Changeset{data: data}, channel_names)
      when is_struct(data, Item) and is_list(channel_names),
      do:
        multi
        |> Multi.run(name, fn repo, changes ->
          case get_unique_item(repo, item_cs |> Ecto.Changeset.apply_changes()) do
            nil ->
              channels = channel_names |> Enum.map(&(changes |> Map.get(&1)))

              item_cs
              |> Ecto.Changeset.change(
                channel_items: channels |> Enum.map(&%ChannelItem{channel: &1})
              )
              |> repo.insert

            db_item ->
              {:ok, db_item}
          end
        end)

  def get_or_insert(multi, name, item = %Ecto.Changeset{data: data}, channel_name)
      when is_struct(data, Item),
      do: get_or_insert(multi, name, item, [channel_name])

  defp get_unique_item(repo, %Item{show: show}) when not is_nil(show),
    do:
      from(i in Item, join: s in Show, on: s.id == i.id, where: s.name == ^show.name)
      |> repo.one()
end

alias Ecto.Multi
alias MediaWatch.Catalog.{Channel, Item}
alias MediaWatch.Repo

channels =
  %{
    france_inter: %{name: "France Inter", url: "https://www.franceinter.fr"},
    france_culture: %{name: "France Culture", url: "https://www.franceculture.fr"},
    france_info: %{name: "France Info", url: "https://www.francetvinfo.fr"},
    rmc: %{name: "RMC", url: "https://rmc.bfmtv.com/"},
    rtl: %{name: "RTL", url: "https://www.rtl.fr"}
  }
  |> Map.new(fn {k, v} -> {k, v |> Channel.changeset()} end)

items =
  %{
    invite_7h50:
      {%{
         show: %{
           name: "L'invité de 7h50",
           url: "https://www.franceinter.fr/emissions/invite-de-7h50"
         },
         sources: [%{rss_feed: %{url: "http://radiofrance-podcast.net/podcast09/rss_11710.xml"}}]
       }, :france_inter},
    invite_8h20:
      {%{
         show: %{name: "L'invité de 8h20'", url: "https://www.franceinter.fr/emissions/l-invite"},
         sources: [%{rss_feed: %{url: "http://radiofrance-podcast.net/podcast09/rss_10239.xml"}}]
       }, :france_inter},
    invite_des_matins:
      {%{
         show: %{
           name: "L'Invité(e) des Matins",
           url: "https://www.franceculture.fr/emissions/linvite-des-matins"
         },
         sources: [%{rss_feed: %{url: "https://radiofrance-podcast.net/podcast09/rss_13983.xml"}}]
       }, :france_culture},
    la_grande_table_idees:
      {%{
         show: %{
           name: "La Grande Table idées",
           url: "https://www.franceculture.fr/emissions/la-grande-table-2eme-partie"
         },
         sources: [%{rss_feed: %{url: "https://radiofrance-podcast.net/podcast09/rss_12360.xml"}}]
       }, :france_culture},
    "8h30_france_info":
      {%{
         show: %{
           name: "8h30 franceinfo",
           url: "https://www.francetvinfo.fr/replay-radio/8h30-fauvelle-dely/"
         },
         sources: [%{rss_feed: %{url: "https://radiofrance-podcast.net/podcast09/rss_16370.xml"}}]
       }, :france_info},
    bourdin_direct:
      {%{
         show: %{
           name: "Bourdin Direct",
           url: "https://rmc.bfmtv.com/emission/bourdin-direct/"
         },
         sources: [%{rss_feed: %{url: "https://podcast.rmc.fr/channel30/RMCInfochannel30.xml"}}]
       }, :rmc},
    invite_rtl:
      {%{
         show: %{name: "L'invité de RTL", url: "https://www.rtl.fr/programmes/l-invite-de-rtl"},
         sources: [%{rss_feed: %{url: "https://www.rtl.fr/podcast/linvite-de-rtl.xml"}}]
       }, :rtl},
    invite_rtl_soir:
      {%{
         show: %{
           name: "L'invité de RTL Soir",
           url: "https://www.rtl.fr/programmes/l-invite-de-rtl-soir"
         },
         sources: [%{rss_feed: %{url: "https://www.rtl.fr/podcast/l-invite-de-rtl-soir.xml"}}]
       }, :rtl}
  }
  |> Map.new(fn {k, {v, channels}} -> {k, {v |> Item.changeset(), channels}} end)

Multi.new()
|> Utils.get_or_insert(channels)
|> Utils.get_or_insert(items)
|> Repo.transaction()
