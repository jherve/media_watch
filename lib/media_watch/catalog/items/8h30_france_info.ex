defmodule MediaWatch.Catalog.Item.Le8h30FranceInfo do
  use MediaWatch.Catalog.ItemWorker,
    show: %{
      name: "8h30 franceinfo",
      url: "https://www.francetvinfo.fr/replay-radio/8h30-fauvelle-dely/",
      airing_schedule: "30 8 * * *",
      duration_minutes: 25
    },
    sources: [%{rss_feed: %{url: "https://radiofrance-podcast.net/podcast09/rss_16370.xml"}}],
    channels: [MediaWatch.Catalog.Channel.FranceInfo]
end
