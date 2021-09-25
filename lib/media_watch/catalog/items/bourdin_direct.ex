defmodule MediaWatch.Catalog.Item.BourdinDirect do
  use MediaWatch.Catalog.Catalogable
  use MediaWatch.Snapshots.Snapshotable
  use MediaWatch.Parsing.Parsable
  use MediaWatch.Parsing.Sliceable
  use MediaWatch.Analysis.Describable
  use MediaWatch.Analysis.Recurrent

  def get_item_args(),
    do: %{
      show: %{
        name: "Bourdin Direct",
        url: "https://rmc.bfmtv.com/emission/bourdin-direct/"
      }
    }

  def get_sources(),
    do: [%{rss_feed: %{url: "https://podcast.rmc.fr/channel30/RMCInfochannel30.xml"}}]

  def get_channel_names(), do: ["RMC"]
end
