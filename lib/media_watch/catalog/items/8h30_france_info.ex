defmodule MediaWatch.Catalog.Item.Le8h30FranceInfo do
  use MediaWatch.Catalog.Catalogable
  use MediaWatch.Snapshots.Snapshotable
  use MediaWatch.Parsing.Parsable
  use MediaWatch.Parsing.Sliceable
  use MediaWatch.Analysis.Describable
  use MediaWatch.Analysis.Recurrent

  def get_item_args(),
    do: %{
      show: %{
        name: "8h30 franceinfo",
        url: "https://www.francetvinfo.fr/replay-radio/8h30-fauvelle-dely/"
      }
    }

  def get_sources(),
    do: [%{rss_feed: %{url: "https://radiofrance-podcast.net/podcast09/rss_16370.xml"}}]

  def get_channel_names(), do: ["France Info"]
end
