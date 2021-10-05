defmodule MediaWatch.Catalog.Item.InviteDesMatins do
  use MediaWatch.Catalog.ItemWorker,
    show: %{
      name: "L'Invité(e) des Matins",
      url: "https://www.franceculture.fr/emissions/linvite-des-matins",
      airing_schedule: "40 7 * * MON-FRI",
      duration_minutes: 45
    },
    sources: [%{rss_feed: %{url: "https://radiofrance-podcast.net/podcast09/rss_13983.xml"}}],
    channels: [MediaWatch.Catalog.Channel.FranceCulture]

  import Ecto.Changeset
  alias MediaWatch.Parsing.Slice.RssEntry

  @impl true
  def into_slice_cs(attrs, parsed),
    do: super(attrs, parsed) |> cast_assoc(:rss_entry, with: &rss_entry_extra_check/2)

  defp rss_entry_extra_check(entry, attrs),
    do:
      RssEntry.changeset(entry, attrs)
      # Les 'entries' dans ce feed contiennent aussi toutes les chroniques de l'émission, qui ne nous
      # intéressent pas.
      |> validate_format(
        :link,
        ~r|^https://www.franceculture.fr/emissions/l-invite-(e-)?des-matins/|
      )
end
