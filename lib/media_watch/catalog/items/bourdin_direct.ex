defmodule MediaWatch.Catalog.Item.BourdinDirect do
  use MediaWatch.Catalog.Item
  use MediaWatch.Catalog.Source
  use MediaWatch.Snapshots.Snapshot
  use MediaWatch.Parsing.ParsedSnapshot
  use MediaWatch.Parsing.Slice

  @impl true
  def get_item_args(),
    do: %{
      show: %{
        name: "Bourdin Direct",
        url: "https://rmc.bfmtv.com/emission/bourdin-direct/"
      }
    }

  @impl true
  def get_sources(),
    do: [%{rss_feed: %{url: "https://podcast.rmc.fr/channel30/RMCInfochannel30.xml"}}]

  @impl true
  def get_channel_names(), do: ["RMC"]
end
