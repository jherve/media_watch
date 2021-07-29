defmodule MediaWatch.Parsing.ParsedSnapshot do
  use Ecto.Schema
  import Ecto.Changeset
  alias MediaWatch.Snapshots.Snapshot
  alias MediaWatch.Analysis.Facet
  alias __MODULE__, as: ParsedSnapshot
  @primary_key false

  schema "parsed_snapshots" do
    belongs_to :snapshot, Snapshot, foreign_key: :id, primary_key: true
    field :data, :map

    Ecto.Schema.timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(parsed \\ %ParsedSnapshot{}, attrs) do
    parsed
    |> cast(attrs, [:id, :data])
    |> validate_required([:data])
    |> cast_assoc(:snapshot, required: true)
    |> unique_constraint(:id)
  end

  def slice(parsed = %ParsedSnapshot{data: data, snapshot: %{xml: xml}}) when not is_nil(xml) do
    data
    |> Map.get("entries")
    |> Enum.map(&Facet.changeset(%Facet{parsed_snapshot: parsed}, %{show_occurrence: &1}))
  end
end
