defmodule MediaWatch.Catalog.Source do
  @behaviour MediaWatch.Snapshots.Snapshotable
  use Ecto.Schema
  import Ecto.Changeset
  alias MediaWatch.Catalog.Item
  alias MediaWatch.Catalog.Source.RssFeed
  alias MediaWatch.Snapshots.Snapshot
  alias __MODULE__, as: Source

  schema "sources" do
    has_one :rss_feed, RssFeed, foreign_key: :id
    belongs_to :item, Item, foreign_key: :item_id
  end

  @doc false
  def changeset(strategy \\ %Source{}, attrs) do
    strategy
    |> cast(attrs, [:id])
    |> cast_assoc(:rss_feed)
  end

  @impl true
  def get_snapshot(source) do
    with actual = %struct{} <- source |> get_actual_source,
         {:ok, attrs} <- actual |> struct.get_snapshot() do
      {:ok, Snapshot.changeset(%Snapshot{source: source}, attrs)}
    end
  end

  defp get_actual_source(%Source{rss_feed: feed}) when not is_nil(feed), do: feed
end
