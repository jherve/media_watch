defmodule MediaWatchInventory.Item.QuestionsPolitiques do
  use MediaWatchInventory.Item

  import Ecto.Changeset
  alias MediaWatch.Parsing.Slice.RssEntry

  @impl MediaWatch.Parsing.Sliceable
  def into_slice_cs(attrs, parsed),
    do: super(attrs, parsed) |> cast_assoc(:rss_entry, with: &rss_entry_extra_check/2)

  defp rss_entry_extra_check(entry, attrs),
    do:
      RssEntry.changeset(entry, attrs)
      |> validate_format(:link, ~r|^https://www.franceinter.fr/emissions/questions-politiques/|)
end
