defmodule MediaWatch.Catalog.Item.LaGrandeTableIdees do
  use MediaWatch.Catalog.Item,
    show: %{
      name: "La Grande Table idées",
      url: "https://www.franceculture.fr/emissions/la-grande-table-2eme-partie"
    },
    sources: [%{rss_feed: %{url: "https://radiofrance-podcast.net/podcast09/rss_12360.xml"}}],
    channel_names: ["France Culture"]

  use MediaWatch.Catalog.Source
  use MediaWatch.Snapshots.Snapshot
  use MediaWatch.Parsing.ParsedSnapshot
  use MediaWatch.Parsing.Slice
end
