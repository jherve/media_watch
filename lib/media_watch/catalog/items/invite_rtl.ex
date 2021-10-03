defmodule MediaWatch.Catalog.Item.InviteRTL do
  use MediaWatch.Catalog.Item.Layout.RTL,
    show: %{
      name: "L'invité de RTL",
      url: "https://www.rtl.fr/programmes/l-invite-de-rtl",
      airing_schedule: "45 7 * * MON-FRI",
      duration_minutes: 10
    },
    sources: [%{rss_feed: %{url: "https://www.rtl.fr/podcast/linvite-de-rtl.xml"}}],
    channel_names: ["RTL"]
end
