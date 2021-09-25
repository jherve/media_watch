defmodule MediaWatch.Catalog.Item.InviteRTL do
  use MediaWatch.Catalog.Catalogable
  use MediaWatch.Snapshots.Snapshotable
  use MediaWatch.Parsing.Parsable
  use MediaWatch.Parsing.Sliceable
  use MediaWatch.Analysis.Describable
  use MediaWatch.Analysis.Recurrent

  def get_item_args(),
    do: %{show: %{name: "L'invité de RTL", url: "https://www.rtl.fr/programmes/l-invite-de-rtl"}}

  def get_sources(),
    do: [%{rss_feed: %{url: "https://www.rtl.fr/podcast/linvite-de-rtl.xml"}}]

  def get_channel_names(), do: ["RTL"]
end
