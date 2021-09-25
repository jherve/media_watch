defmodule MediaWatch.Catalog.Item.LaGrandeTableIdees do
  use MediaWatch.Catalog.Catalogable
  use MediaWatch.Snapshots.Snapshotable
  use MediaWatch.Parsing.Parsable
  use MediaWatch.Parsing.Sliceable
  use MediaWatch.Analysis.Describable
  use MediaWatch.Analysis.Recurrent

  def get_item_args(),
    do: %{
      show: %{
        name: "La Grande Table idées",
        url: "https://www.franceculture.fr/emissions/la-grande-table-2eme-partie"
      }
    }

  def get_sources(),
    do: [%{rss_feed: %{url: "https://radiofrance-podcast.net/podcast09/rss_12360.xml"}}]

  def get_channel_names(), do: ["France Culture"]
end
