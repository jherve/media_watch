defmodule MediaWatch.Catalog.Source.RssFeed do
  @type t() :: %__MODULE__{
          __meta__: Ecto.Schema.Metadata.t(),
          id: integer() | nil,
          url: binary()
        }

  use Ecto.Schema
  import Ecto.Changeset
  alias MediaWatch.Http
  alias __MODULE__, as: RssFeed

  schema "catalog_rss_feeds" do
    field :url, :string
  end

  @doc false
  def changeset(feed \\ %RssFeed{}, attrs) do
    feed
    |> cast(attrs, [:url])
    |> validate_required([:url])
    |> unique_constraint([:url])
  end

  def into_snapshot_attrs(%RssFeed{url: url}),
    do: with({:ok, content} <- Http.get_body(url), do: {:ok, %{xml: %{content: content}}})

  def parse(content) when is_binary(content), do: content |> ElixirFeedParser.parse()
  def prune(parsed_content), do: {:ok, parsed_content |> prune_root |> prune_entries}

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
