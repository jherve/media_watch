defmodule MediaWatch.Analysis.SliceUsage do
  use Ecto.Schema
  import Ecto.Changeset
  alias MediaWatch.Parsing.Slice
  alias MediaWatch.Analysis.{ShowOccurrence, Description}
  alias __MODULE__, as: SliceUsage
  @required_fields [:used, :slice_id]
  @optional_fields [:id, :description_id, :show_occurrence_id]
  @all_fields @required_fields ++ @optional_fields

  schema "slices_usages" do
    belongs_to :slice, Slice
    belongs_to :show_occurrence, ShowOccurrence
    belongs_to :description, Description, references: :item_id
    field :used, :boolean
  end

  @doc false
  def changeset(usage \\ %SliceUsage{}, attrs) do
    usage
    |> cast(attrs, @all_fields)
    |> validate_required(@required_fields)
    |> unique_constraint([:show_occurrence_id, :slice_id])
    |> unique_constraint([:description_id, :slice_id])
    |> check_constraint(:show_occurrence_id, name: "slices_usages_only_one_of")
  end
end