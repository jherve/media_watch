defmodule MediaWatchInventory.Channel do
  defmacro __using__(_opts) do
    quote do
      @behaviour MediaWatch.Catalog.Catalogable
      import Ecto.Query
      alias MediaWatch.Repo

      @config Application.compile_env(:media_watch, MediaWatchInventory)[:channels][__MODULE__] ||
                raise("Config for #{__MODULE__} should be set")

      @name @config[:name] || raise("`name` should be set")
      @url @config[:url] || raise("`url` should be set")

      @impl true
      def query(),
        do: from(c in MediaWatch.Catalog.Channel, as: :item, where: c.module == ^__MODULE__)

      @impl true
      def insert() do
        %{module: __MODULE__, name: @name, url: @url}
        |> MediaWatch.Catalog.Channel.changeset()
        |> Repo.insert()
      end

      @impl true
      def get() do
        from(c in query()) |> Repo.one()
      end
    end
  end
end
