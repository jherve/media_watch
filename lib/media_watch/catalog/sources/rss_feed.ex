defmodule MediaWatch.Catalog.Source.RssFeed do
  @behaviour MediaWatch.Snapshots.Snapshotable
  use Ecto.Schema
  import Ecto.Changeset
  alias MediaWatch.Http
  alias MediaWatch.Catalog.Source
  alias MediaWatch.Snapshots.Snapshot.Xml
  alias __MODULE__, as: RssFeed

  schema "rss_feeds" do
    field :url, :string
    belongs_to :strategy, Source, foreign_key: :id, define_field: false
  end

  @doc false
  def changeset(feed \\ %RssFeed{}, attrs) do
    feed
    |> cast(attrs, [:url])
    |> validate_required([:url])
    |> unique_constraint([:url])
  end

  @impl true
  def get_snapshot(%RssFeed{url: url}),
    do: with({:ok, content} <- Http.get_body(url), do: {:ok, %{xml: %{content: content}}})
end
