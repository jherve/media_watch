defmodule MediaWatch.Analysis.ShowOccurrence do
  use Ecto.Schema
  import Ecto.Changeset
  alias MediaWatch.Catalog.Show
  alias MediaWatch.Parsing.Slice
  alias __MODULE__, as: ShowOccurrence
  @all_fields [:title, :description, :link, :date_start, :show_id, :slice_ids]
  @required_fields [:title, :description, :date_start]

  schema "show_occurrences" do
    belongs_to :show, Show
    field :title, :string
    field :description, :string
    field :link, :string
    field :date_start, :utc_datetime

    field :slice_ids, {:array, :id}
  end

  @doc false
  def changeset(occurrence \\ %ShowOccurrence{}, attrs) do
    occurrence
    |> cast(attrs, @all_fields)
    |> validate_required(@required_fields)
    |> unique_constraint([:show_id, :date_start])
  end

  def from(%Slice{id: id, type: :rss_entry, rss_entry: entry}, show_id) do
    changeset(%{
      show_id: show_id,
      title: entry.title,
      description: entry.description,
      link: entry.link,
      date_start: entry.pub_date,
      slice_ids: [id]
    })
  end
end
