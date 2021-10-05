defmodule MediaWatch.Catalog.Item.QuestionsPolitiques do
  use MediaWatch.Catalog.ItemWorker,
    show: %{
      name: "Questions politiques",
      url: "https://www.franceinter.fr/emissions/questions-politiques",
      airing_schedule: "0 12 * * SUN",
      duration_minutes: 55
    },
    sources: [%{rss_feed: %{url: "https://radiofrance-podcast.net/podcast09/rss_16170.xml"}}],
    channels: [MediaWatch.Catalog.Channel.FranceInter]

  import Ecto.Changeset
  alias MediaWatch.Parsing.Slice.RssEntry

  @impl true
  def into_slice_cs(attrs, parsed),
    do: super(attrs, parsed) |> cast_assoc(:rss_entry, with: &rss_entry_extra_check/2)

  defp rss_entry_extra_check(entry, attrs),
    do:
      RssEntry.changeset(entry, attrs)
      |> validate_format(:link, ~r|^https://www.franceinter.fr/emissions/questions-politiques/|)
end
