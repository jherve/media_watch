defmodule MediaWatch.Analysis.Slice.ShowOccurrence do
  use Ecto.Schema
  import Ecto.Changeset
  alias __MODULE__, as: ShowOccurrence
  @all_fields [:title, :description, :url]
  @required_fields @all_fields

  schema "show_occurrences" do
    field :title, :string
    field :description, :string
    field :url, :string
  end

  @doc false
  def changeset(occurrence \\ %ShowOccurrence{}, attrs) do
    occurrence
    |> cast(attrs, @all_fields)
    |> validate_required(@required_fields)
  end
end
