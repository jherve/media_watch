defmodule MediaWatch.Catalog.Item.InviteDesMatins do
  use MediaWatch.Catalog.Catalogable
  use MediaWatch.Snapshots.Snapshotable
  use MediaWatch.Parsing.Parsable
  use MediaWatch.Parsing.Sliceable
  use MediaWatch.Analysis.Describable
  use MediaWatch.Analysis.Recurrent

  def get_item_args(),
    do: %{
      show: %{
        name: "L'Invité(e) des Matins",
        url: "https://www.franceculture.fr/emissions/linvite-des-matins"
      }
    }

  def get_sources(),
    do: [%{rss_feed: %{url: "https://radiofrance-podcast.net/podcast09/rss_13983.xml"}}]

  def get_channel_names(), do: ["France Culture"]
end
