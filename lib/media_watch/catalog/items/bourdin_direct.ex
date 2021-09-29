defmodule MediaWatch.Catalog.Item.BourdinDirect do
  use MediaWatch.Catalog.Item,
    show: %{name: "Bourdin Direct", url: "https://rmc.bfmtv.com/emission/bourdin-direct/"},
    sources: [%{rss_feed: %{url: "https://podcast.rmc.fr/channel30/RMCInfochannel30.xml"}}],
    channel_names: ["RMC"]
end
