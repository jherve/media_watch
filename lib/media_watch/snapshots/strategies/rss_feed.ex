defmodule MediaWatch.Snapshots.Strategy.RssFeed do
  @behaviour MediaWatch.Snapshots.Snapshotable
  use Ecto.Schema
  import Ecto.Changeset
  alias MediaWatch.Http
  alias MediaWatch.Snapshots.Strategy
  alias __MODULE__, as: RssFeed

  schema "rss_feeds" do
    field :url, :string
    belongs_to :strategy, Strategy, foreign_key: :id, define_field: false
  end

  @doc false
  def changeset(feed \\ %RssFeed{}, attrs) do
    feed
    |> cast(attrs, [:url])
    |> validate_required([:url])
    |> unique_constraint([:url])
  end

  @impl true
  def get_snapshot(%RssFeed{url: url}), do: Http.get_body(url)
end
