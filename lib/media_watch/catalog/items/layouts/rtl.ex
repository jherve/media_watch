defmodule MediaWatch.Catalog.Item.Layout.RTL do
  import Ecto.Changeset
  use MediaWatch.Parsing.Slice

  def describe(slice),
    do:
      super(slice)
      |> update_change(:description, &remove_html/1)

  defp remove_html(text) do
    with {:ok, parsed} <- Floki.parse_fragment(text), do: parsed |> Floki.text()
  end

  defmacro __using__(_) do
    quote do
      use MediaWatch.Parsing.Slice

      @impl true
      defdelegate describe(slice), to: MediaWatch.Catalog.Item.Layout.RTL
    end
  end
end
