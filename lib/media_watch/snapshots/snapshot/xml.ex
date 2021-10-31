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

  def parse_snapshot(%Xml{content: content}), do: content |> RssFeed.parse()
  def prune_snapshot(parsed_data) when is_map(parsed_data), do: parsed_data |> RssFeed.prune()
end
