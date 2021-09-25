defmodule MediaWatch.Catalog.Source do
  use Ecto.Schema
  import Ecto.Changeset
  alias MediaWatch.Catalog.Item
  alias MediaWatch.Catalog.Source.RssFeed
  alias MediaWatch.Snapshots.Snapshot
  alias __MODULE__, as: Source

  schema "sources" do
    field :type, Ecto.Enum, values: [:rss_feed]

    has_one :rss_feed, RssFeed, foreign_key: :id
    belongs_to :item, Item, foreign_key: :item_id
  end

  @doc false
  def changeset(strategy \\ %Source{}, attrs) do
    strategy
    |> cast(attrs, [:id])
    |> cast_assoc(:rss_feed)
    |> set_type()
  end

  def make_snapshot(source) do
    with actual = %struct{} <- source |> get_actual_source,
         {:ok, attrs} <- actual |> struct.make_snapshot() do
      {:ok, Snapshot.changeset(%Snapshot{source: source}, attrs)}
    end
  end

  defp get_actual_source(%Source{rss_feed: feed}) when not is_nil(feed), do: feed

  defp set_type(cs) do
    if has_field?(cs, :rss_feed), do: cs |> put_change(:type, :rss_feed), else: cs
  end

  defp has_field?(cs, field) do
    case cs |> fetch_field(field) do
      {_, val} when not is_nil(val) -> true
      _ -> false
    end
  end
end
