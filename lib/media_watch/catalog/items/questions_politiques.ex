defmodule MediaWatch.Catalog.Item.QuestionsPolitiques do
  use MediaWatch.Catalog.ItemWorker,
    show: %{
      name: "Questions politiques",
      url: "https://www.franceinter.fr/emissions/questions-politiques"
    },
    sources: [%{rss_feed: %{url: "https://radiofrance-podcast.net/podcast09/rss_16170.xml"}}],
    channel_names: ["France Inter"]
end
