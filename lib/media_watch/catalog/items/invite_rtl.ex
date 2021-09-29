defmodule MediaWatch.Catalog.Item.InviteRTL do
  use MediaWatch.Catalog.Item,
    show: %{name: "L'invité de RTL", url: "https://www.rtl.fr/programmes/l-invite-de-rtl"},
    sources: [%{rss_feed: %{url: "https://www.rtl.fr/podcast/linvite-de-rtl.xml"}}],
    channel_names: ["RTL"]

  use MediaWatch.Catalog.Source
  use MediaWatch.Snapshots.Snapshot
  use MediaWatch.Parsing.ParsedSnapshot
  use MediaWatch.Catalog.Item.Layout.RTL
end
