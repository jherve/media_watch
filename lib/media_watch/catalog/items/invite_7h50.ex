defmodule MediaWatch.Catalog.Item.Invite7h50 do
  use MediaWatch.Catalog.Item,
    show: %{name: "L'invité de 7h50", url: "https://www.franceinter.fr/emissions/invite-de-7h50"},
    sources: [%{rss_feed: %{url: "http://radiofrance-podcast.net/podcast09/rss_11710.xml"}}],
    channel_names: ["France Inter"]

  use MediaWatch.Catalog.Source
  use MediaWatch.Snapshots.Snapshot
  use MediaWatch.Parsing.ParsedSnapshot
  use MediaWatch.Parsing.Slice
end
