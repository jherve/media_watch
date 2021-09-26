defmodule MediaWatch.Catalog.Item.Le8h30FranceInfo do
  use MediaWatch.Catalog.Item
  use MediaWatch.Catalog.Source
  use MediaWatch.Snapshots.Snapshot
  use MediaWatch.Parsing.ParsedSnapshot
  use MediaWatch.Parsing.Slice

  @impl true
  def get_item_args(),
    do: %{
      show: %{
        name: "8h30 franceinfo",
        url: "https://www.francetvinfo.fr/replay-radio/8h30-fauvelle-dely/"
      }
    }

  @impl true
  def get_sources(),
    do: [%{rss_feed: %{url: "https://radiofrance-podcast.net/podcast09/rss_16370.xml"}}]

  @impl true
  def get_channel_names(), do: ["France Info"]
end
