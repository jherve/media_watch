defmodule MediaWatch.Catalog.Item.InviteRTLSoir do
  use MediaWatch.Catalog.Item.Layout.RTL,
    show: %{
      name: "L'invité de RTL Soir",
      url: "https://www.rtl.fr/programmes/l-invite-de-rtl-soir"
    },
    sources: [%{rss_feed: %{url: "https://www.rtl.fr/podcast/l-invite-de-rtl-soir.xml"}}],
    channel_names: ["RTL"]
end
