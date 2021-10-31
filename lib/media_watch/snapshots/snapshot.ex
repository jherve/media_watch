defmodule MediaWatch.Snapshots.Snapshot do
  @type t() :: %__MODULE__{
          __meta__: Ecto.Schema.Metadata.t(),
          id: integer() | nil,
          type: atom(),
          source: MediaWatch.Catalog.Source.t() | nil,
          xml: MediaWatch.Snapshots.Snapshot.Xml.t() | nil,
          html: MediaWatch.Snapshots.Snapshot.Html.t() | nil
        }

  use Ecto.Schema
  import Ecto.Changeset
  alias MediaWatch.Catalog.Source
  alias MediaWatch.Snapshots.Snapshot.{Xml, Html}
  alias MediaWatch.Parsing.ParsedSnapshot
  alias __MODULE__, as: Snapshot
  @required_fields [:type, :url]

  schema "snapshots" do
    field :url, :string
    field :type, Ecto.Enum, values: [:xml, :html]

    belongs_to :source, Source
    has_one :xml, Xml, foreign_key: :id
    has_one :html, Html, foreign_key: :id

    Ecto.Schema.timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(snapshot \\ %Snapshot{}, attrs) do
    snapshot
    |> cast(attrs, [:id, :url])
    |> cast_assoc(:source, required: true)
    |> cast_assoc(:xml)
    |> cast_assoc(:html)
    |> set_type()
    |> validate_required(@required_fields)
  end

  def parse(snap = %Snapshot{}, parsable) do
    with {:ok, parsed} <- snap |> parsable.parse_snapshot(),
         {:ok, pruned} <- parsed |> parsable.prune_snapshot(snap) do
      {:ok,
       ParsedSnapshot.changeset(%ParsedSnapshot{snapshot: snap, source: snap.source}, %{
         data: pruned
       })}
    end
  end

  @spec parse_snapshot(Snapshot.t()) :: {:ok, map()} | {:error, any()}
  def parse_snapshot(%Snapshot{type: :xml, xml: xml}), do: xml |> Xml.parse_snapshot()
  def parse_snapshot(%Snapshot{type: :html, html: html}), do: html |> Html.parse_snapshot()

  @spec prune_snapshot(map(), Snapshot.t()) :: {:ok, map()} | {:error, any()}
  def prune_snapshot(parsed, %Snapshot{type: :xml}), do: parsed |> Xml.prune_snapshot()

  def prune_snapshot(_, %Snapshot{type: :html}),
    do: raise("A custom implementation must be provided for html snapshots")

  defp set_type(cs) do
    cond do
      has_field?(cs, :xml) -> cs |> put_change(:type, :xml)
      has_field?(cs, :html) -> cs |> put_change(:type, :html)
      true -> cs
    end
  end

  defp has_field?(cs, field) do
    case cs |> fetch_field(field) do
      {_, val} when not is_nil(val) -> true
      _ -> false
    end
  end
end
