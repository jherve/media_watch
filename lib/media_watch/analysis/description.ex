defmodule MediaWatch.Analysis.Description do
  use Ecto.Schema
  import Ecto.Changeset
  alias MediaWatch.Parsing.Slice
  alias MediaWatch.Catalog.Item
  alias __MODULE__, as: Description
  @primary_key false
  @all_fields [:item_id, :title, :description, :link, :image, :slice_ids]
  @required_fields [:item_id, :title, :description]

  schema "descriptions" do
    belongs_to :item, Item

    field :title, :string
    field :description, :string
    field :link, :string
    field :image, :map

    field :slice_ids, {:array, :id}
  end

  @doc false
  def changeset(desc \\ %Description{}, attrs) do
    desc
    |> cast(attrs, @all_fields)
    |> validate_required(@required_fields)
    |> validate_length(:slice_ids, min: 1)
  end

  def from(%Slice{id: id, type: :rss_channel_description, rss_channel_description: desc}, item_id) do
    changeset(%{
      item_id: item_id,
      title: desc.title,
      description: desc.description,
      link: desc.link,
      image: desc.image,
      slice_ids: [id]
    })
  end
end
