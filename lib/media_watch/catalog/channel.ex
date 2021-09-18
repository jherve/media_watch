defmodule MediaWatch.Catalog.Channel do
  use Ecto.Schema
  alias MediaWatch.Catalog.ChannelItem

  schema "channels" do
    field :name, :string
    field :url, :string

    has_many :channel_items, ChannelItem
    has_many :items, through: [:channel_items, :item]
  end
end
