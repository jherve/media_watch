defmodule MediaWatch.Catalog.Item.InviteRTLSoir do
  use MediaWatch.Catalog.Item.Layout.RTL,
    show: %{
      name: "L'invité de RTL Soir",
      url: "https://www.rtl.fr/programmes/l-invite-de-rtl-soir",
      airing_schedule: "20 18 * * MON-FRI",
      duration_minutes: 10
    },
    sources: [%{rss_feed: %{url: "https://www.rtl.fr/podcast/l-invite-de-rtl-soir.xml"}}],
    channels: [MediaWatch.Catalog.Channel.RTL]
end
