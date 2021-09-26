defmodule MediaWatch.Catalog.Channel do
  @callback get_module() :: atom()
  @callback get_name() :: binary()
  @callback get_url() :: binary()

  use Ecto.Schema
  import Ecto.Changeset
  alias __MODULE__, as: Channel
  alias MediaWatch.Catalog
  alias MediaWatch.Catalog.ChannelItem

  schema "channels" do
    field :module, Ecto.Enum, values: Catalog.all_channel_modules()
    field :name, :string
    field :url, :string

    has_many :channel_items, ChannelItem
    has_many :items, through: [:channel_items, :item]
  end

  @doc false
  def changeset(channel \\ %Channel{}, attrs) do
    channel
    |> cast(attrs, [:module, :name, :url])
    |> validate_required([:module, :name, :url])
    |> unique_constraint(:module)
  end

  defmacro __using__(_opts) do
    quote do
      use MediaWatch.Catalog.Catalogable
      @behaviour Channel

      def get_module(), do: __MODULE__

      @impl true
      def insert(repo) do
        %{module: get_module(), name: get_name(), url: get_url()}
        |> Channel.changeset()
        |> repo.insert()
      end

      @impl true
      def get(repo) do
        import Ecto.Query
        module = get_module()

        from(c in Channel, where: c.module == ^module)
        |> repo.one()
      end
    end
  end
end
