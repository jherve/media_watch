defmodule MediaWatch.Catalog.ChannelItem do
  use Ecto.Schema
  import Ecto.Changeset
  alias MediaWatch.Catalog.{Item, Channel}
  alias __MODULE__
  @primary_key false
  @fields [:channel_id, :item_id]

  schema "channel_items" do
    belongs_to :item, Item, primary_key: true
    belongs_to :channel, Channel, primary_key: true
  end

  @doc false
  def changeset(ci \\ %ChannelItem{}, attrs) do
    ci
    |> cast(attrs, @fields)
    |> validate_required(@fields)
    |> unique_constraint(@fields)
  end

  def is_unique_error?(%{
        errors: [
          channel_id:
            {_, [constraint: :unique, constraint_name: "channel_items_channel_id_item_id_index"]}
        ]
      }),
      do: true

  def is_unique_error?(%Ecto.Changeset{}), do: false
end
