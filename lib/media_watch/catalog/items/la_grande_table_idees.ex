defmodule MediaWatch.Catalog.Item.LaGrandeTableIdees do
  use MediaWatch.Catalog.Item
  use MediaWatch.Catalog.Source
  use MediaWatch.Snapshots.Snapshot
  use MediaWatch.Parsing.ParsedSnapshot
  use MediaWatch.Parsing.Slice

  @impl true
  def get_item_args(),
    do: %{
      show: %{
        name: "La Grande Table idées",
        url: "https://www.franceculture.fr/emissions/la-grande-table-2eme-partie"
      }
    }

  @impl true
  def get_sources(),
    do: [%{rss_feed: %{url: "https://radiofrance-podcast.net/podcast09/rss_12360.xml"}}]

  @impl true
  def get_channel_names(), do: ["France Culture"]
end
