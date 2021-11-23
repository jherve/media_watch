defmodule MediaWatchInventory.Layout.Europe1 do
  defmacro __using__(opts) do
    quote bind_quoted: [opts: opts] do
      use MediaWatchInventory.Item, opts
      alias MediaWatch.Analysis.ShowOccurrence

      @impl MediaWatch.Parsing.Sliceable
      def get_slice_kind(slice = %{type: rss_entry, rss_entry: %{title: title}}) do
        # The RSS feed has a bad tendency of mixing extracts of the show with the
        # actual show. This function aims at finding a relevant entry from which to
        # read the occurrences' properties.
        if title =~ "EXTRAIT", do: :excerpt, else: nil
      end

      def get_slice_kind(slice), do: nil
    end
  end
end
