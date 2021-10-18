defmodule MediaWatch.Snapshots.Snapshot do
  @type t() :: %__MODULE__{
          __meta__: Ecto.Schema.Metadata.t(),
          id: integer() | nil,
          type: atom(),
          source: MediaWatch.Catalog.Source.t() | nil,
          xml: MediaWatch.Snapshots.Snapshot.Xml.t() | nil
        }

  use Ecto.Schema
  import Ecto.Changeset
  alias MediaWatch.Catalog.Source
  alias MediaWatch.Snapshots.Snapshot.Xml
  alias MediaWatch.Parsing.ParsedSnapshot
  alias __MODULE__, as: Snapshot

  schema "snapshots" do
    field :type, Ecto.Enum, values: [:xml]

    belongs_to :source, Source
    has_one :xml, Xml, foreign_key: :id

    Ecto.Schema.timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(snapshot \\ %Snapshot{}, attrs) do
    snapshot
    |> cast(attrs, [:id])
    |> cast_assoc(:source, required: true)
    |> cast_assoc(:xml)
    |> set_type()
    |> validate_required([:type])
  end

  def parse(snap = %Snapshot{type: :xml, xml: xml}) when not is_nil(xml) do
    with {:ok, data} <- xml |> Xml.into_parsed_snapshot_data() do
      {:ok,
       ParsedSnapshot.changeset(%ParsedSnapshot{snapshot: snap, source: snap.source}, %{
         data: data
       })}
    end
  end

  defp set_type(cs) do
    case cs |> fetch_field(:xml) do
      {_, %Xml{}} -> cs |> put_change(:type, :xml)
    end
  end
end
