defmodule MediaWatch.Parsing.ParsedSnapshot do
  @type t() :: %__MODULE__{
          __meta__: Ecto.Schema.Metadata.t(),
          id: integer() | nil,
          snapshot: MediaWatch.Snapshots.Snapshot.t() | nil,
          source: MediaWatch.Catalog.Source.t() | nil,
          data: map()
        }

  use Ecto.Schema
  import Ecto.Changeset
  alias MediaWatch.Catalog.Source
  alias MediaWatch.Snapshots.Snapshot
  alias __MODULE__, as: ParsedSnapshot

  schema "parsed_snapshots" do
    belongs_to :snapshot, Snapshot
    belongs_to :source, Source
    field :data, Ecto.MapWithTuple

    Ecto.Schema.timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(parsed \\ %ParsedSnapshot{}, attrs) do
    parsed
    |> cast(attrs, [:id, :data])
    |> validate_required([:data])
    |> cast_assoc(:snapshot, required: true)
    |> cast_assoc(:source, required: true)
    |> unique_constraint(:snapshot_id)
  end
end
