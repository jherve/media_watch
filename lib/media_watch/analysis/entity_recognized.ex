defmodule MediaWatch.Analysis.EntityRecognized do
  use Ecto.Schema
  import Ecto.Changeset
  alias MediaWatch.Parsing.Slice
  alias __MODULE__, as: EntityRecognized
  @required_fields [:label, :type, :field]
  @all_fields @required_fields

  schema "entities_recognized" do
    field :label, :string
    field :type, :string
    field :field, :string
    belongs_to :slice, Slice
  end

  @doc false
  def changeset(entity \\ %EntityRecognized{}, attrs) do
    entity
    |> cast(attrs, @all_fields)
    |> cast_assoc(:slice, required: true)
    |> validate_required(@required_fields)
    |> unique_constraint([:slice_id, :label, :type, :field])
  end
end
