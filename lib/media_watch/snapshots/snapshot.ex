defmodule MediaWatch.Snapshots.Snapshot do
  @behaviour MediaWatch.Parsing.Parsable
  use Ecto.Schema
  import Ecto.Changeset
  alias MediaWatch.Catalog.Source
  alias MediaWatch.Snapshots.Snapshot.Xml
  alias MediaWatch.Parsing.ParsedSnapshot
  alias __MODULE__, as: Snapshot

  schema "snapshots" do
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
  end

  @impl true
  def parse(snap = %Snapshot{xml: xml}) when not is_nil(xml) do
    with {:ok, attrs} <- xml |> Xml.parse() do
      {:ok, ParsedSnapshot.changeset(%ParsedSnapshot{snapshot: snap}, attrs)}
    end
  end
end
