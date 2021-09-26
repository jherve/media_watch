defmodule MediaWatch.Catalog.Item.Invite8h20 do
  use MediaWatch.Catalog.CatalogableItem
  use MediaWatch.Snapshots.Snapshotable
  use MediaWatch.Parsing.Parsable
  use MediaWatch.Parsing.Sliceable
  use MediaWatch.Analysis.Describable
  use MediaWatch.Analysis.Recurrent

  def get_item_args(),
    do: %{
      show: %{name: "L'invité de 8h20'", url: "https://www.franceinter.fr/emissions/l-invite"}
    }

  def get_sources(),
    do: [%{rss_feed: %{url: "http://radiofrance-podcast.net/podcast09/rss_10239.xml"}}]

  def get_channel_names(), do: ["France Inter"]
end
