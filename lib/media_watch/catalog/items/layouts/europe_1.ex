defmodule MediaWatch.Catalog.Item.Layout.Europe1 do
  defmacro __using__(opts) do
    quote bind_quoted: [opts: opts] do
      use MediaWatch.Catalog.ItemWorker, opts
      alias MediaWatch.Analysis.ShowOccurrence

      @impl true
      def update_occurrence(occ, used, discarded, new) do
        # The RSS feed has a bad tendency of mixing extracts of the show with the
        # actual show. This function aims at finding a relevant entry from which to
        # read the occurrences' properties.
        usable_slices = used ++ new

        case usable_slices |> Enum.group_by(&(&1.rss_entry.title =~ "EXTRAIT")) do
          %{true: extracts, false: relevant = [%{rss_entry: entry} = first_relevant | _]} ->
            # If slices are identified as "extrait", we discard them all and use the "first
            # of the others" to update the occurrence's properties
            super(occ, relevant, discarded ++ extracts, [])
            |> ShowOccurrence.changeset(%{
              title: entry.title,
              description: entry.description,
              link: entry.link
            })

          _ ->
            # Else we keep the occurrence as-is
            super(occ, usable_slices, discarded, [])
        end
      end
    end
  end
end
