defmodule MediaWatch.Catalog.Item.LaGrandeTableIdees do
  use MediaWatch.Catalog.Item

  import Ecto.Changeset
  alias MediaWatch.Parsing.Slice.RssEntry

  @impl MediaWatch.Parsing.Sliceable
  def into_slice_cs(attrs, parsed),
    do: super(attrs, parsed) |> cast_assoc(:rss_entry, with: &rss_entry_extra_check/2)

  defp rss_entry_extra_check(entry, attrs),
    do:
      RssEntry.changeset(entry, attrs)
      # Les 'entries' dans ce feed mélangent des émissions différentes,
      # et celle que l'on recherche doit avoir ce lien.
      |> validate_format(:link, ~r|^https://www.franceculture.fr/emissions/la-grande-table-idees|)
end
