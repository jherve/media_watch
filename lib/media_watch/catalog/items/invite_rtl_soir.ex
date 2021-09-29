defmodule MediaWatch.Catalog.Item.InviteRTLSoir do
  use MediaWatch.Catalog.Item,
    show: %{
      name: "L'invité de RTL Soir",
      url: "https://www.rtl.fr/programmes/l-invite-de-rtl-soir"
    },
    sources: [%{rss_feed: %{url: "https://www.rtl.fr/podcast/l-invite-de-rtl-soir.xml"}}],
    channel_names: ["RTL"]

  use MediaWatch.Catalog.Source
  use MediaWatch.Snapshots.Snapshot
  use MediaWatch.Parsing.ParsedSnapshot
  use MediaWatch.Catalog.Item.Layout.RTL
end
