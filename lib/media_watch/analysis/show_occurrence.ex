defmodule MediaWatch.Analysis.ShowOccurrence do
  use Ecto.Schema
  import Ecto.Changeset
  require Ecto.Query
  alias MediaWatch.Catalog.Show
  alias MediaWatch.Parsing.Slice
  alias MediaWatch.Analysis.Invitation
  alias __MODULE__, as: ShowOccurrence
  @required_fields [:title, :description, :airing_time, :slot_start, :slot_end, :slices_used]
  @optional_fields [:link, :show_id, :slices_discarded]
  @all_fields @required_fields ++ @optional_fields

  schema "show_occurrences" do
    belongs_to :show, Show, on_replace: :mark_as_invalid
    field :title, :string
    field :description, :string
    field :link, :string
    field :airing_time, :utc_datetime
    field :slot_start, :utc_datetime
    field :slot_end, :utc_datetime

    field :slices_used, {:array, :id}
    field :slices_discarded, {:array, :id}, default: []

    has_many :invitations, Invitation
    has_many :guests, through: [:invitations, :person]
  end

  @doc false
  def changeset(occurrence \\ %ShowOccurrence{}, attrs) do
    occurrence
    |> cast(attrs, @all_fields)
    |> validate_required(@required_fields)
    |> validate_length(:slices_used, min: 1)
    |> unique_constraint([:show_id, :airing_time])
  end

  def from(
        %Slice{id: id, type: :rss_entry, rss_entry: entry = %{pub_date: pub_date}},
        module,
        show_id
      ) do
    {start, end_} = module.get_time_slot(pub_date)

    changeset(%{
      show_id: show_id,
      title: entry.title,
      description: entry.description,
      link: entry.link,
      airing_time: pub_date |> module.get_airing_time() |> into_utc(),
      slot_start: start |> into_utc,
      slot_end: end_ |> into_utc,
      slices_used: [id]
    })
  end

  def get_slices_from_occurrence(occ, repo), do: query_slices_from_occurrence(occ) |> repo.all()

  def get_occurrence_at(datetime, module) do
    repo = module.get_repo()
    query = Ecto.Query.from(i in module.query(), select: i.id)

    Ecto.Query.from(o in ShowOccurrence,
      where: o.show_id in subquery(query) and o.airing_time == ^datetime
    )
    |> repo.one!
  end

  defp query_slices_from_occurrence(occ = %ShowOccurrence{}),
    do:
      Ecto.Query.from(s in Slice,
        where: s.id in ^(occ.slices_used ++ occ.slices_discarded),
        preload: ^Slice.preloads()
      )

  # Errors in date conversion are simply propagated as-is
  defp into_utc(e = {:error, _}), do: e
  defp into_utc(date), do: date |> Timex.Timezone.convert("UTC")
end
