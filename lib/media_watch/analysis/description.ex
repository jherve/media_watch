defmodule MediaWatch.Analysis.Description do
  use Ecto.Schema
  import Ecto.Changeset
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
    |> validate_required(@required_fields)
    |> unique_constraint(:item_id)
  end
end
