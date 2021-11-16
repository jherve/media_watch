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

  def handle_error(
        {:error,
         cs = %{
           errors: [
             item_id: {_, [constraint: :unique, constraint_name: "descriptions_item_id_index"]}
           ]
         }},
        repo
      ) do
    with {_, item_id} <- cs |> fetch_field(:item_id),
         desc when not is_nil(desc) <- Description |> repo.get_by(item_id: item_id),
         do: {:error, {:unique, desc}}
  end

  def handle_error(ok_or_other_error, _), do: ok_or_other_error
end
