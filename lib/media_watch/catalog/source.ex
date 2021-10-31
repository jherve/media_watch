defmodule MediaWatch.Catalog.Source do
  @type t() :: %__MODULE__{
          __meta__: Ecto.Schema.Metadata.t(),
          id: integer() | nil,
          type: atom(),
          rss_feed: MediaWatch.Catalog.Source.RssFeed.t() | nil,
          item: MediaWatch.Catalog.Item.t() | nil
        }

  use Ecto.Schema
  import Ecto.Changeset
  alias MediaWatch.Catalog.Item
  alias MediaWatch.Catalog.Source.{RssFeed, WebIndexPage}
  alias MediaWatch.Snapshots.Snapshot
  alias __MODULE__, as: Source

  schema "catalog_sources" do
    field :type, Ecto.Enum, values: [:rss_feed, :web_index_page]

    has_one :rss_feed, RssFeed, foreign_key: :id
    has_one :web_index_page, WebIndexPage, foreign_key: :id
    belongs_to :item, Item, foreign_key: :item_id
  end

  @doc false
  def changeset(strategy \\ %Source{}, attrs) do
    strategy
    |> cast(attrs, [:id])
    |> cast_assoc(:rss_feed)
    |> cast_assoc(:web_index_page)
    |> set_type()
  end

  def make_snapshot(source = %{type: :rss_feed, rss_feed: feed}) when not is_nil(feed) do
    with {:ok, attrs} <- feed |> RssFeed.into_snapshot_attrs() do
      {:ok, Snapshot.changeset(%Snapshot{source: source}, attrs)}
    end
  end

  def make_snapshot(source = %{type: :web_index_page, web_index_page: page})
      when not is_nil(page) do
    with {:ok, attrs} <- page |> WebIndexPage.into_snapshot_attrs() do
      {:ok, Snapshot.changeset(%Snapshot{source: source}, attrs)}
    end
  end

  defp set_type(cs) do
    cond do
      has_field?(cs, :rss_feed) -> cs |> put_change(:type, :rss_feed)
      has_field?(cs, :web_index_page) -> cs |> put_change(:type, :web_index_page)
      true -> cs
    end
  end

  defp has_field?(cs, field) do
    case cs |> fetch_field(field) do
      {_, val} when not is_nil(val) -> true
      _ -> false
    end
  end
end
