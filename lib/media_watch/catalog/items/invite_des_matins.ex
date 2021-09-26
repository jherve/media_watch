defmodule MediaWatch.Catalog.Item.InviteDesMatins do
  use MediaWatch.Catalog.Item
  use MediaWatch.Catalog.Source
  use MediaWatch.Snapshots.Snapshot
  use MediaWatch.Parsing.ParsedSnapshot
  use MediaWatch.Parsing.Slice

  @impl true
  def get_item_args(),
    do: %{
      show: %{
        name: "L'Invité(e) des Matins",
        url: "https://www.franceculture.fr/emissions/linvite-des-matins"
      }
    }

  @impl true
  def get_sources(),
    do: [%{rss_feed: %{url: "https://radiofrance-podcast.net/podcast09/rss_13983.xml"}}]

  @impl true
  def get_channel_names(), do: ["France Culture"]
end
