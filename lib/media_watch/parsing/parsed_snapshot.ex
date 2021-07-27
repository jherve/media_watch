defmodule MediaWatch.Parsing.ParsedSnapshot do
  use Ecto.Schema
  import Ecto.Changeset
  alias MediaWatch.Snapshots.Snapshot
  alias __MODULE__, as: ParsedSnapshot

  schema "parsed_snapshots" do
    belongs_to :snapshot, Snapshot
    field :data, :map
  end

  @doc false
  def changeset(parsed \\ %ParsedSnapshot{}, attrs) do
    parsed
    |> cast(attrs, [:id, :data])
    |> validate_required([:data])
    |> cast_assoc(:snapshot, required: true)
  end
end
