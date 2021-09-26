defmodule MediaWatch.Catalog.Catalogable do
  @callback get_module() :: atom()
  @callback get_item_args() :: map()
  @callback get_sources() :: list(map())
  @callback get_channel_names() :: list(binary())
  @callback insert(Ecto.Repo.t()) :: {:ok, MediaWatch.Catalog.Item.t()} | {:error, any()}
  @callback get(Ecto.Repo.t()) :: MediaWatch.Catalog.Item.t() | nil

  defmacro __using__(_opts) do
    quote do
      @behaviour MediaWatch.Catalog.Catalogable

      def get_module(), do: __MODULE__

      def insert(repo) do
        channels = get_channels(repo)

        %{
          module: get_module(),
          sources: get_sources()
        }
        |> Map.merge(get_item_args())
        |> MediaWatch.Catalog.Item.changeset()
        |> Ecto.Changeset.change(
          channel_items: channels |> Enum.map(&%MediaWatch.Catalog.ChannelItem{channel: &1})
        )
        |> repo.insert()
      end

      def get(repo) do
        import Ecto.Query
        alias MediaWatch.Catalog.Item

        module = get_module()

        from(i in Item,
          where: i.module == ^module,
          preload: [:channels, :show, sources: [:rss_feed]]
        )
        |> repo.one()
      end

      defp get_channels(repo) do
        import Ecto.Query
        channel_names = get_channel_names()

        from(c in MediaWatch.Catalog.Channel, where: c.name in ^channel_names)
        |> repo.all()
      end
    end
  end
end
