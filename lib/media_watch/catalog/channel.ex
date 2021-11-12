defmodule MediaWatch.Catalog.Channel do
  use Ecto.Schema
  import Ecto.Changeset
  alias __MODULE__, as: Channel
  alias MediaWatch.Catalog.ChannelItem

  schema "catalog_channels" do
    field :module, Ecto.Enum, values: MediaWatchInventory.all_channel_modules()
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
end
