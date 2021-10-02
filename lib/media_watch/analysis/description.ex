defmodule MediaWatch.Analysis.Description do
  use Ecto.Schema
  import Ecto.Changeset
  alias MediaWatch.Parsing.Slice
  alias MediaWatch.Catalog.Item
  alias __MODULE__, as: Description
  @primary_key false
  @all_fields [:item_id, :title, :description, :link, :image, :slices_used]
  @required_fields [:item_id, :title, :description, :slices_used]

  schema "descriptions" do
    belongs_to :item, Item

    field :title, :string
    field :description, :string
    field :link, :string
    field :image, :map

    field :slices_used, {:array, :id}
    field :slices_discarded, {:array, :id}, default: []
  end

  @doc false
  def changeset(desc \\ %Description{}, attrs) do
    desc
    |> cast(attrs, @all_fields)
    |> validate_required(@required_fields)
    |> validate_length(:slices_used, min: 1)
  end

  def from(%Slice{id: id, type: :rss_channel_description, rss_channel_description: desc}, item_id) do
    changeset(%{
      item_id: item_id,
      title: desc.title,
      description: desc.description,
      link: desc.link,
      image: desc.image,
      slices_used: [id]
    })
  end
end
