defmodule MediaWatch.Analysis.Facet do
  use Ecto.Schema
  import Ecto.Changeset
  alias MediaWatch.Catalog.Source
  alias MediaWatch.Parsing.ParsedSnapshot
  alias MediaWatch.Analysis.Facet.ShowOccurrence
  alias __MODULE__, as: Facet

  schema "facets" do
    field :date_start, :utc_datetime
    field :date_end, :utc_datetime

    belongs_to :source, Source
    belongs_to :parsed_snapshot, ParsedSnapshot
    has_one :show_occurrence, ShowOccurrence, foreign_key: :id

    Ecto.Schema.timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(facet \\ %Facet{}, attrs) do
    facet
    |> cast(attrs, [:id, :date_start, :date_end])
    |> validate_required([:date_start, :date_end])
    |> cast_assoc(:parsed_snapshot, required: true)
    |> cast_assoc(:source, required: true)
    |> cast_assoc(:show_occurrence)
  end
end
