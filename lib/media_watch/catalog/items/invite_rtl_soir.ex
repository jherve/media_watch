defmodule MediaWatch.Catalog.Item.InviteRTLSoir do
  use MediaWatch.Catalog.CatalogableItem
  use MediaWatch.Snapshots.Snapshotable
  use MediaWatch.Parsing.Parsable
  use MediaWatch.Parsing.Sliceable
  use MediaWatch.Analysis.Describable
  use MediaWatch.Analysis.Recurrent

  def get_item_args(),
    do: %{
      show: %{
        name: "L'invité de RTL Soir",
        url: "https://www.rtl.fr/programmes/l-invite-de-rtl-soir"
      }
    }

  def get_sources(),
    do: [%{rss_feed: %{url: "https://www.rtl.fr/podcast/l-invite-de-rtl-soir.xml"}}]

  def get_channel_names(), do: ["RTL"]
end
