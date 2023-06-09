defmodule MediaWatchInventory.Layout.RTL do
  defmacro __using__(opts) do
    quote bind_quoted: [opts: opts] do
      use MediaWatchInventory.Item, opts
      import Ecto.Changeset

      @impl MediaWatch.Analysis.Describable
      def get_description_attrs(item_id, slice),
        do:
          super(item_id, slice)
          |> Map.update!(:description, &remove_html/1)

      defp remove_html(text) do
        with {:ok, parsed} <- Floki.parse_fragment(text), do: parsed |> Floki.text()
      end
    end
  end
end
