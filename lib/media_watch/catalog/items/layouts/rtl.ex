defmodule MediaWatch.Catalog.Item.Layout.RTL do
  defmacro __using__(opts) do
    quote bind_quoted: [opts: opts] do
      use MediaWatch.Catalog.ItemWorker, opts
      import Ecto.Changeset

      @impl true
      def describe(slice),
        do:
          super(slice)
          |> update_change(:description, &remove_html/1)

      defp remove_html(text) do
        with {:ok, parsed} <- Floki.parse_fragment(text), do: parsed |> Floki.text()
      end
    end
  end
end