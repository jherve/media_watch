defmodule MediaWatch.Snapshots.Snapshot.Xml do
  @behaviour MediaWatch.Parsing.Parsable
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

  @impl true
  def parse(%Xml{content: content}) do
    with {:ok, parsed} <- content |> ElixirFeedParser.parse(),
         do: {:ok, %{data: parsed |> prune_root |> prune_entries}}
  end

  defp prune_entries(parsed = %{entries: entries}) when is_map(parsed),
    do: %{
      parsed
      | entries: entries |> Enum.map(&(&1 |> Map.take([:title, :url, :description, :updated])))
    }

  defp prune_root(parsed) when is_map(parsed),
    do: parsed |> Map.take([:entries, :title, :url, :description, :image])
end
