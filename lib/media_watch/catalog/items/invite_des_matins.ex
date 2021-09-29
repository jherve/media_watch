defmodule MediaWatch.Catalog.Item.InviteDesMatins do
  use MediaWatch.Catalog.Item,
    show: %{
      name: "L'Invité(e) des Matins",
      url: "https://www.franceculture.fr/emissions/linvite-des-matins"
    },
    sources: [%{rss_feed: %{url: "https://radiofrance-podcast.net/podcast09/rss_13983.xml"}}],
    channel_names: ["France Culture"]

  use MediaWatch.Catalog.Source
  use MediaWatch.Snapshots.Snapshot
  use MediaWatch.Parsing.ParsedSnapshot
  use MediaWatch.Parsing.Slice
end
