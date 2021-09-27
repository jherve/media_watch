defmodule MediaWatch.Catalog.Item.InviteRTLSoir do
  use MediaWatch.Catalog.Item
  use MediaWatch.Catalog.Source
  use MediaWatch.Snapshots.Snapshot
  use MediaWatch.Parsing.ParsedSnapshot
  use MediaWatch.Catalog.Item.Layout.RTL

  @impl true
  def get_item_args(),
    do: %{
      show: %{
        name: "L'invité de RTL Soir",
        url: "https://www.rtl.fr/programmes/l-invite-de-rtl-soir"
      }
    }

  @impl true
  def get_sources(),
    do: [%{rss_feed: %{url: "https://www.rtl.fr/podcast/l-invite-de-rtl-soir.xml"}}]

  @impl true
  def get_channel_names(), do: ["RTL"]
end
