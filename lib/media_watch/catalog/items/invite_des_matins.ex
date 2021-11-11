defmodule MediaWatch.Catalog.Item.InviteDesMatins do
  use MediaWatch.Catalog.Item

  import Ecto.Changeset
  alias MediaWatch.Parsing.Slice.RssEntry

  @impl MediaWatch.Analysis.Recognisable
  def in_entities_blacklist?(label), do: label in ["L Invité(e"]

  @impl MediaWatch.Parsing.Sliceable
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
