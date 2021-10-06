defmodule MediaWatch.Catalog.Item.Invite8h20 do
  use MediaWatch.Catalog.ItemWorker,
    show: %{
      name: "L'invité de 8h20'",
      url: "https://www.franceinter.fr/emissions/l-invite",
      airing_schedule: "20 8 * * MON-FRI",
      duration_minutes: 25
    },
    sources: [%{rss_feed: %{url: "http://radiofrance-podcast.net/podcast09/rss_10239.xml"}}],
    channels: [MediaWatch.Catalog.Channel.FranceInter]
end
