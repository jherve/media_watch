defmodule MediaWatch.Catalog.Item do
  # TODO this typespec is incomplete
  @type t() :: %__MODULE__{
          __meta__: Ecto.Schema.Metadata.t(),
          id: integer() | nil,
          module: atom()
        }
  @callback get_module() :: atom()
  @callback get_item_args() :: map()
  @callback get_sources() :: list(map())
  @callback get_channel_names() :: list(binary())

  use Ecto.Schema
  import Ecto.Changeset
  alias __MODULE__, as: Item
  alias MediaWatch.Catalog.Show
  alias MediaWatch.Catalog.Source
  alias MediaWatch.Catalog.ChannelItem
  alias MediaWatch.Analysis.Description

  schema "watched_items" do
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
      use MediaWatch.Catalog.Catalogable
      @behaviour MediaWatch.Catalog.Item

      def get_module(), do: __MODULE__

      def insert(repo) do
        channels = get_channels(repo)

        %{module: get_module(), sources: get_sources()}
        |> Map.merge(get_item_args())
        |> Item.changeset()
        |> change(channel_items: channels |> Enum.map(&%ChannelItem{channel: &1}))
        |> repo.insert()
      end

      def get(repo) do
        import Ecto.Query
        module = get_module()

        from(i in Item,
          where: i.module == ^module,
          preload: [:channels, :show, sources: [:rss_feed]]
        )
        |> repo.one()
      end

      defp get_channels(repo) do
        import Ecto.Query
        alias MediaWatch.Catalog.Channel
        channel_names = get_channel_names()

        from(c in Channel, where: c.name in ^channel_names)
        |> repo.all()
      end
    end
  end
end
