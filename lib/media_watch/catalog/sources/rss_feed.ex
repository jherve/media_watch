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

  schema "rss_feeds" do
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
end
