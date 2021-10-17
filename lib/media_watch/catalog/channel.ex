defmodule MediaWatch.Catalog.Channel do
  use Ecto.Schema
  import Ecto.Changeset
  alias __MODULE__, as: Channel
  alias MediaWatch.Catalog
  alias MediaWatch.Catalog.ChannelItem

  schema "catalog_channels" do
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
      use MediaWatch.Catalog.Catalogable, repo: MediaWatch.Repo
      import Ecto.Query

      @config Application.compile_env(:media_watch, MediaWatch.Catalog)[:channels][__MODULE__] ||
                raise("Config for #{__MODULE__} should be set")

      @name @config[:name] || raise("`name` should be set")
      @url @config[:url] || raise("`url` should be set")

      @impl true
      def query(), do: from(c in Channel, as: :item, where: c.module == ^__MODULE__)

      @impl true
      def insert() do
        repo = get_repo()

        %{module: __MODULE__, name: @name, url: @url}
        |> Channel.changeset()
        |> MediaWatch.Repo.insert_and_retry(repo)
      end

      @impl true
      def get() do
        import Ecto.Query
        repo = get_repo()

        from(c in query()) |> repo.one()
      end
    end
  end
end
