defmodule MediaWatch.Analysis.SliceUsage do
  use Ecto.Schema
  import Ecto.Changeset
  alias MediaWatch.Parsing.Slice
  alias MediaWatch.Analysis.{ShowOccurrence, Description}
  alias __MODULE__, as: SliceUsage
  @required_fields [:type, :slice_id]
  @optional_fields [:id, :description_id, :show_occurrence_id]
  @all_fields @required_fields ++ @optional_fields
  @types [:item_description, :show_occurrence_description, :show_occurrence_excerpt]

  schema "slices_usages" do
    belongs_to :slice, Slice
    belongs_to :show_occurrence, ShowOccurrence
    belongs_to :description, Description, references: :item_id
    field :type, Ecto.Enum, values: @types
  end

  def types(), do: @types

  @doc false
  def create_changeset(attrs) do
    %SliceUsage{}
    |> cast(attrs, @all_fields)
    |> validate_required(@required_fields)
    |> unique_constraint([:show_occurrence_id, :slice_id])
    |> unique_constraint([:description_id, :slice_id])
    |> check_constraint(:show_occurrence_id,
      name: "slices_usages_show_occurrence_id_when_occurrence"
    )
    |> check_constraint(:description_id,
      name: "slices_usages_description_id_when_item_description"
    )
  end

  def classify(%Slice{type: :rss_channel_description}), do: :item_description
  def classify(%Slice{type: :rss_entry}), do: :show_occurrence_description
  def classify(%Slice{type: :html_list_item}), do: :show_occurrence_description
  def classify(%Slice{type: :open_graph}), do: :item_description
end
