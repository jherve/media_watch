defmodule MediaWatch.Catalog.Item.InviteDesMatins do
  use MediaWatch.Catalog.ItemWorker,
    show: %{
      name: "L'Invité(e) des Matins",
      url: "https://www.franceculture.fr/emissions/linvite-des-matins",
      airing_schedule: "40 7 * * MON-FRI",
      duration_minutes: 45
    },
    sources: [%{rss_feed: %{url: "https://radiofrance-podcast.net/podcast09/rss_13983.xml"}}],
    channel_names: ["France Culture"]

  import Ecto.Changeset
  alias MediaWatch.Parsing.Slice

  @impl true
  def create_occurrence(slice = %Slice{}),
    # Les 'entries' dans ce feed contiennent aussi toutes les chroniques de l'émission, qui ne nous
    # intéressent pas.
    do:
      super(slice)
      |> validate_format(
        :link,
        ~r|^https://www.franceculture.fr/emissions/l-invite-(e-)?des-matins/|
      )
end
