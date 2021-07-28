defmodule MediaWatch.Analysis.Facet do
  use Ecto.Schema
  import Ecto.Changeset
  alias MediaWatch.Parsing.ParsedSnapshot
  alias __MODULE__, as: Facet

  schema "facets" do
    belongs_to :parsed_snapshot, ParsedSnapshot

    Ecto.Schema.timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(facet \\ %Facet{}, attrs) do
    facet
    |> cast(attrs, [:id])
    |> cast_assoc(:parsed_snapshot, required: true)
  end
end
