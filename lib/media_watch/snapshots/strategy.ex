defmodule MediaWatch.Snapshots.Strategy do
  use Ecto.Schema
  import Ecto.Changeset
  alias MediaWatch.Catalog.Item
  alias MediaWatch.Snapshots.Strategy.RssFeed
  alias __MODULE__, as: Strategy

  schema "snapshot_strategies" do
    has_one :rss_feed, RssFeed, foreign_key: :id
    belongs_to :watched_item, Item, foreign_key: :watched_item_id
  end

  @doc false
  def changeset(strategy \\ %Strategy{}, attrs) do
    strategy
    |> cast(attrs, [:id])
    |> cast_assoc(:rss_feed)
  end

  def get_actual_strategy(%Strategy{rss_feed: feed}) when not is_nil(feed), do: feed
end
