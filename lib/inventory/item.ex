defmodule MediaWatchInventory.Item do
  defmacro __using__(_opts) do
    quote do
      @config Application.compile_env(:media_watch, MediaWatchInventory)[:items][__MODULE__] ||
                raise("Config for #{__MODULE__} should be set")

      @show @config[:show]

      @item_args (cond do
                    not is_nil(@show) -> %{show: @show}
                    true -> raise("At least one of [`show`] should be set")
                  end)

      @sources @config[:sources] || raise("`sources` should be set")
      @channels @config[:channels] || raise("`channels` should be set")

      @behaviour MediaWatch.Catalog.Catalogable
      @behaviour MediaWatch.Parsing.Parsable
      use MediaWatch.Parsing.Parsable.Generic
      @behaviour MediaWatch.Parsing.Sliceable
      use MediaWatch.Parsing.Sliceable.Generic
      @behaviour MediaWatch.Analysis.Analyzable
      use MediaWatch.Analysis.Analyzable.Generic
      @behaviour MediaWatch.Analysis.Describable
      use MediaWatch.Analysis.Describable.Generic
      @behaviour MediaWatch.Analysis.Recognisable
      use MediaWatch.Analysis.Recognisable.Generic
      @behaviour MediaWatch.Analysis.Hosted
      use MediaWatch.Analysis.Hosted.Generic, @show
      @behaviour MediaWatch.Analysis.Recurrent
      use MediaWatch.Analysis.Recurrent.Generic, @show

      import Ecto.Query
      alias MediaWatch.Repo

      @impl MediaWatch.Catalog.Catalogable
      def query(),
        do: from(i in MediaWatch.Catalog.Item, as: :item, where: i.module == ^__MODULE__)

      @impl MediaWatch.Catalog.Catalogable
      def insert() do
        import Ecto.Changeset
        alias MediaWatch.Catalog.{Item, ChannelItem}
        channels = @channels |> Enum.map(& &1.get())

        %{module: __MODULE__, sources: @sources}
        |> Map.merge(@item_args)
        |> Item.changeset()
        |> change(channel_items: channels |> Enum.map(&%ChannelItem{channel: &1}))
        |> Repo.insert()
      end

      @impl MediaWatch.Catalog.Catalogable
      def get() do
        from(i in query(), preload: [:channels, :show, sources: [:rss_feed, :web_index_page]])
        |> Repo.one()
      end
    end
  end
end
