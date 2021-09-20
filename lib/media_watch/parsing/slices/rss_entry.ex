defmodule MediaWatch.Parsing.Slice.RssEntry do
  use Ecto.Schema
  import Ecto.Changeset
  alias __MODULE__, as: RssEntry
  @all_fields [:guid, :title, :description, :link, :pub_date]
  @required_fields [:guid, :title, :description, :pub_date]

  schema "rss_entries" do
    field :guid, :string
    field :title, :string
    field :description, :string
    field :link, :string
    field :pub_date, :utc_datetime
  end

  @doc false
  def changeset(occurrence \\ %RssEntry{}, attrs) do
    occurrence
    |> cast(attrs, @all_fields)
    |> validate_required(@required_fields)
    |> unique_constraint(:guid)
  end
end
