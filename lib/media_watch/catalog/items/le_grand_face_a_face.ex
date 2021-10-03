defmodule MediaWatch.Catalog.Item.LeGrandFaceAFace do
  use MediaWatch.Catalog.ItemWorker,
    show: %{
      name: "Le Grand Face-à-face",
      url: "https://www.franceinter.fr/emissions/le-grand-face-a-face",
      airing_schedule: "0 12 * * SAT",
      duration_minutes: 55
    },
    sources: [%{rss_feed: %{url: "https://radiofrance-podcast.net/podcast09/rss_18558.xml"}}],
    channels: [MediaWatch.Catalog.Channel.FranceInter]
end
