defmodule MediaWatch.Catalog.ChannelItem do
  use Ecto.Schema
  alias MediaWatch.Catalog.{Item, Channel}
  @primary_key false

  schema "channel_items" do
    belongs_to :item, Item, primary_key: true
    belongs_to :channel, Channel, primary_key: true
  end
end
