defmodule MediaWatch.Catalog.Item.QuestionsPolitiques do
  use MediaWatch.Catalog.ItemWorker,
    show: %{
      name: "Questions politiques",
      url: "https://www.franceinter.fr/emissions/questions-politiques",
      airing_schedule: "0 12 * * SUN",
      duration_minutes: 55
    },
    sources: [%{rss_feed: %{url: "https://radiofrance-podcast.net/podcast09/rss_16170.xml"}}],
    channels: [MediaWatch.Catalog.Channel.FranceInter]
end
