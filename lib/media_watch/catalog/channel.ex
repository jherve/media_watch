defmodule MediaWatch.Catalog.Channel do
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

  defmacro __using__(opts) do
    quote bind_quoted: [opts: opts] do
      use MediaWatch.Catalog.Catalogable, repo: MediaWatch.Repo

      @name opts[:name] || raise("`name` should be set")
      @url opts[:url] || raise("`url` should be set")

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

        from(c in Channel, where: c.module == ^__MODULE__)
        |> repo.one()
      end
    end
  end
end
