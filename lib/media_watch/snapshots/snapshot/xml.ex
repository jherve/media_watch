defmodule MediaWatch.Snapshots.Snapshot.Xml do
  @type t() :: %__MODULE__{
          __meta__: Ecto.Schema.Metadata.t(),
          id: integer() | nil,
          content: binary()
        }

  use Ecto.Schema
  import Ecto.Changeset
  alias MediaWatch.Catalog.Source.RssFeed
  alias __MODULE__, as: Xml

  schema "snapshots_xml" do
    field :content, :string
  end

  @doc false
  def changeset(xml \\ %Xml{}, attrs) do
    xml
    |> cast(attrs, [:content])
    |> validate_required([:content])
    |> unique_constraint(:content)
  end

  def into_parsed_snapshot_data(%Xml{content: content}) do
    with {:ok, parsed} <- content |> RssFeed.parse(), do: parsed |> RssFeed.prune()
  end
end
