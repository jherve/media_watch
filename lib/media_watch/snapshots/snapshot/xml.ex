defmodule MediaWatch.Snapshots.Snapshot.Xml do
  @type t() :: %__MODULE__{
          __meta__: Ecto.Schema.Metadata.t(),
          id: integer() | nil,
          content: binary()
        }

  use Ecto.Schema
  import Ecto.Changeset
  alias __MODULE__, as: Xml

  schema "snapshots_xml" do
    field :content, :string
  end

  @doc false
  def changeset(xml \\ %Xml{}, attrs) do
    xml
    |> cast(attrs, [:content])
    |> validate_required([:content])
  end

  def into_parsed_snapshot_data(%Xml{content: content}) do
    with {:ok, parsed} <- content |> ElixirFeedParser.parse(),
         do: {:ok, parsed |> prune_root |> prune_entries}
  end

  defp prune_entries(parsed = %{entries: entries}) when is_map(parsed),
    do: %{
      parsed
      | entries:
          entries
          |> Enum.map(
            &(&1
              |> Map.take([:title, :description, :"rss2:guid", :"rss2:link", :"rss2:pubDate"]))
          )
    }

  defp prune_root(parsed) when is_map(parsed),
    do: parsed |> Map.take([:entries, :title, :url, :description, :image])
end
