defmodule MediaWatch.Catalog.Item do
  use Ecto.Schema
  import Ecto.Changeset
  alias __MODULE__, as: Item
  alias MediaWatch.Catalog.Show
  alias MediaWatch.Catalog.Source
  alias MediaWatch.Catalog.ChannelItem

  schema "watched_items" do
    has_one :show, Show, foreign_key: :id
    has_many :sources, Source, foreign_key: :item_id
    has_many :channel_items, ChannelItem
    has_many :channels, through: [:channel_items, :channel]
  end

  @doc false
  def changeset(item \\ %Item{}, attrs) do
    item
    |> cast(attrs, [:id])
    |> cast_assoc(:show)
    |> validate_required_inclusion([:show])
    |> cast_assoc(:sources, required: true)
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
end
