defmodule MediaWatch.Catalog.Item do
  # TODO this typespec is incomplete
  @type t() :: %__MODULE__{
          __meta__: Ecto.Schema.Metadata.t(),
          id: integer() | nil,
          module: atom()
        }

  use Ecto.Schema
  import Ecto.Changeset
  alias __MODULE__, as: Item
  alias MediaWatch.Catalog.Show
  alias MediaWatch.Catalog.Source
  alias MediaWatch.Catalog.ChannelItem
  alias MediaWatch.Analysis.Description

  schema "catalog_items" do
    field :module, Ecto.Enum, values: MediaWatch.Catalog.all()
    has_one :show, Show, foreign_key: :id
    has_many :sources, Source, foreign_key: :item_id
    has_many :channel_items, ChannelItem
    has_many :channels, through: [:channel_items, :channel]
    has_one :description, Description
  end

  @doc false
  def changeset(item \\ %Item{}, attrs) do
    item
    |> cast(attrs, [:id, :module])
    |> cast_assoc(:show)
    |> validate_required_inclusion([:show])
    |> cast_assoc(:sources, required: true)
    |> unique_constraint(:module)
  end

  def validate_required_inclusion(changeset, fields) do
    if Enum.any?(fields, &present?(changeset, &1)) do
      changeset
    else
      # Add the error to the first field only since Ecto requires a field name for each error.
      add_error(changeset, hd(fields), "One of these fields must be present: #{inspect(fields)}")
    end
  end

  def present?(changeset, field) do
    case changeset |> fetch_field(field) do
      {_, val} when not is_nil(val) -> true
      {_, nil} -> false
    end
  end

  defmacro __using__(_opts) do
    quote do
      @config Application.compile_env(:media_watch, MediaWatch.Catalog)[:items][__MODULE__] ||
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
      def query(), do: from(i in Item, as: :item, where: i.module == ^__MODULE__)

      @impl MediaWatch.Catalog.Catalogable
      def insert() do
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
