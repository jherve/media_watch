defmodule MediaWatch.Catalog.CatalogableChannel do
  @callback get_module() :: atom()
  @callback get_name() :: binary()
  @callback get_url() :: binary()

  defmacro __using__(_opts) do
    quote do
      @behaviour MediaWatch.Catalog.CatalogableChannel
      @behaviour MediaWatch.Catalog.Catalogable

      def get_module(), do: __MODULE__

      def insert(repo) do
        %{module: get_module(), name: get_name(), url: get_url()}
        |> MediaWatch.Catalog.Channel.changeset()
        |> repo.insert()
      end

      def get(repo) do
        import Ecto.Query
        alias MediaWatch.Catalog.Channel

        module = get_module()

        from(c in Channel, where: c.module == ^module)
        |> repo.one()
      end
    end
  end
end
