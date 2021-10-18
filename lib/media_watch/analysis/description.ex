defmodule MediaWatch.Analysis.Description do
  use Ecto.Schema
  import Ecto.Changeset
  alias MediaWatch.Catalog
  alias MediaWatch.Parsing.Slice
  alias MediaWatch.Catalog.Item
  alias MediaWatch.Analysis.SliceUsage
  alias __MODULE__, as: Description
  @primary_key false
  @required_fields [:item_id, :title, :description]
  @optional_fields [:link, :image]
  @all_fields @required_fields ++ @optional_fields

  schema "descriptions" do
    belongs_to :item, Item

    field :title, :string
    field :description, :string
    field :link, :string
    field :image, :map

    has_many :slice_usages, SliceUsage, references: :item_id, foreign_key: :description_id
    has_many :slices, through: [:slice_usages, :slice]
  end

  @doc false
  def changeset(desc \\ %Description{}, attrs) do
    desc
    |> cast(attrs, @all_fields)
    |> cast_assoc(:slice_usages, required: true)
    |> validate_required(@required_fields)
  end

  def create_description(
        slice = %Slice{id: id, type: :rss_channel_description, rss_channel_description: desc}
      ) do
    item_id = Catalog.get_item_id(slice.source_id)

    changeset(%{
      item_id: item_id,
      title: desc.title,
      description: desc.description,
      link: desc.link,
      image: desc.image,
      slice_usages: [%{slice_id: id, used: true}]
    })
  end

  def create_description_and_store(slice, repo, describable),
    do:
      slice
      |> repo.preload(:rss_channel_description)
      |> describable.create_description()
      |> MediaWatch.Repo.insert_and_retry(repo)
end
