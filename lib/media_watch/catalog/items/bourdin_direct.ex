defmodule MediaWatch.Catalog.Item.BourdinDirect do
  use MediaWatch.Catalog.ItemWorker,
    show: %{
      name: "Bourdin Direct",
      url: "https://rmc.bfmtv.com/emission/bourdin-direct/",
      airing_schedule: "35 8 * * MON-FRI",
      duration_minutes: 25
    },
    sources: [%{rss_feed: %{url: "https://podcast.rmc.fr/channel30/RMCInfochannel30.xml"}}],
    channels: [MediaWatch.Catalog.Channel.RMC]
end
