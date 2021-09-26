defmodule MediaWatch.Catalog.Item.Invite7h50 do
  use MediaWatch.Catalog.CatalogableItem
  use MediaWatch.Snapshots.Snapshotable
  use MediaWatch.Parsing.Parsable
  use MediaWatch.Parsing.Sliceable
  use MediaWatch.Analysis.Describable
  use MediaWatch.Analysis.Recurrent

  def get_item_args(),
    do: %{
      show: %{
        name: "L'invité de 7h50",
        url: "https://www.franceinter.fr/emissions/invite-de-7h50"
      }
    }

  def get_sources(),
    do: [%{rss_feed: %{url: "http://radiofrance-podcast.net/podcast09/rss_11710.xml"}}]

  def get_channel_names(), do: ["France Inter"]
end
