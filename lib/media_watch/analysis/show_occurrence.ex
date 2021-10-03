defmodule MediaWatch.Analysis.ShowOccurrence do
  use Ecto.Schema
  import Ecto.Changeset
  require Ecto.Query
  alias MediaWatch.Catalog.Show
  alias MediaWatch.Parsing.Slice
  alias __MODULE__, as: ShowOccurrence
  @required_fields [:title, :description, :date_start, :slices_used]
  @optional_fields [:link, :show_id, :slices_discarded]
  @all_fields @required_fields ++ @optional_fields

  schema "show_occurrences" do
    belongs_to :show, Show, on_replace: :mark_as_invalid
    field :title, :string
    field :description, :string
    field :link, :string
    field :date_start, :utc_datetime

    field :slices_used, {:array, :id}
    field :slices_discarded, {:array, :id}, default: []
  end

  @doc false
  def changeset(occurrence \\ %ShowOccurrence{}, attrs) do
    occurrence
    |> cast(attrs, @all_fields)
    |> validate_required(@required_fields)
    |> validate_length(:slices_used, min: 1)
    |> unique_constraint([:show_id, :date_start])
    |> unsafe_unique_time_slot()
  end

  def from(%Slice{id: id, type: :rss_entry, rss_entry: entry}, show_id) do
    changeset(%{
      show_id: show_id,
      title: entry.title,
      description: entry.description,
      link: entry.link,
      date_start: entry.pub_date,
      slices_used: [id]
    })
  end

  def unsafe_unique_time_slot(cs) do
    # If the changeset contains a non-null ID, it means that we are doing an
    # update operation on an existing entry, which makes this check undesirable.
    with {_, nil} <- cs |> fetch_field(:id),
         {_, show_id} <- cs |> fetch_field(:show_id),
         {_, date_start} <- cs |> fetch_field(:date_start),
         module <- MediaWatch.Catalog.module_from_show_id(show_id) do
      case module.get_occurrences_within_time_slot(date_start) do
        [] ->
          cs

        occurrences when is_list(occurrences) ->
          cs
          |> add_error(:date_start, "occurrences already exist with same time slot",
            validation: :unsafe_unique_time_slot,
            occurrences: occurrences
          )
      end
    else
      _ -> cs
    end
  end
end
