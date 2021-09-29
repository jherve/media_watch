defmodule MediaWatch.Catalog.Item.Le8h30FranceInfo do
  use MediaWatch.Catalog.Item,
    show: %{
      name: "8h30 franceinfo",
      url: "https://www.francetvinfo.fr/replay-radio/8h30-fauvelle-dely/"
    },
    sources: [%{rss_feed: %{url: "https://radiofrance-podcast.net/podcast09/rss_16370.xml"}}],
    channel_names: ["France Info"]

  use MediaWatch.Catalog.Source
  use MediaWatch.Snapshots.Snapshot
  use MediaWatch.Parsing.ParsedSnapshot
  use MediaWatch.Parsing.Slice
end
