defmodule MediaWatch.Catalog.Item.Invite7h50 do
  use MediaWatch.Catalog.Item
  use MediaWatch.Catalog.Source
  use MediaWatch.Snapshots.Snapshot
  use MediaWatch.Parsing.ParsedSnapshot
  use MediaWatch.Parsing.Slice

  @impl true
  def get_item_args(),
    do: %{
      show: %{
        name: "L'invité de 7h50",
        url: "https://www.franceinter.fr/emissions/invite-de-7h50"
      }
    }

  @impl true
  def get_sources(),
    do: [%{rss_feed: %{url: "http://radiofrance-podcast.net/podcast09/rss_11710.xml"}}]

  @impl true
  def get_channel_names(), do: ["France Inter"]
end
