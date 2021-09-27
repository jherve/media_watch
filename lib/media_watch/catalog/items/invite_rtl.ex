defmodule MediaWatch.Catalog.Item.InviteRTL do
  use MediaWatch.Catalog.Item
  use MediaWatch.Catalog.Source
  use MediaWatch.Snapshots.Snapshot
  use MediaWatch.Parsing.ParsedSnapshot
  use MediaWatch.Catalog.Item.Layout.RTL

  @impl true
  def get_item_args(),
    do: %{show: %{name: "L'invité de RTL", url: "https://www.rtl.fr/programmes/l-invite-de-rtl"}}

  @impl true
  def get_sources(),
    do: [%{rss_feed: %{url: "https://www.rtl.fr/podcast/linvite-de-rtl.xml"}}]

  @impl true
  def get_channel_names(), do: ["RTL"]
end
