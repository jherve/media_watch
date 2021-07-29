defmodule MediaWatch.Analysis.Facet do
  use Ecto.Schema
  import Ecto.Changeset
  alias MediaWatch.Parsing.ParsedSnapshot
  alias MediaWatch.Analysis.Facet.ShowOccurrence
  alias __MODULE__, as: Facet

  schema "facets" do
    belongs_to :parsed_snapshot, ParsedSnapshot
    has_one :show_occurrence, ShowOccurrence, foreign_key: :id

    Ecto.Schema.timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(facet \\ %Facet{}, attrs) do
    facet
    |> cast(attrs, [:id])
    |> cast_assoc(:parsed_snapshot, required: true)
    |> cast_assoc(:show_occurrence)
  end
end
