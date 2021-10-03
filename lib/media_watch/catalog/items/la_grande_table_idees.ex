defmodule MediaWatch.Catalog.Item.LaGrandeTableIdees do
  use MediaWatch.Catalog.ItemWorker,
    show: %{
      name: "La Grande Table idées",
      url: "https://www.franceculture.fr/emissions/la-grande-table-2eme-partie",
      airing_schedule: "55 12 * * MON-FRI",
      duration_minutes: 35
    },
    sources: [%{rss_feed: %{url: "https://radiofrance-podcast.net/podcast09/rss_12360.xml"}}],
    channel_names: ["France Culture"]

  import Ecto.Changeset
  alias MediaWatch.Parsing.Slice

  @impl true
  def create_occurrence(slice = %Slice{}),
    # Les 'entries' dans ce feed mélangent des émissions différentes,
    # et celle que l'on recherche doit avoir ce lien.
    do:
      super(slice)
      |> validate_format(:link, ~r|^https://www.franceculture.fr/emissions/la-grande-table-idees|)
end
