defmodule MediaWatch.Catalog.Item.LInterviewPolitique do
  use MediaWatch.Catalog.ItemWorker,
    show: %{
      name: "L'interview politique",
      url: "https://www.europe1.fr/emissions/linterview-politique-de-8h20"
    },
    sources: [%{rss_feed: %{url: "https://www.europe1.fr/rss/podcasts/interview-8h20.xml"}}],
    channel_names: ["Europe 1"]
end
