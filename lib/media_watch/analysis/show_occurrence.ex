defmodule MediaWatch.Analysis.ShowOccurrence do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query
  alias MediaWatch.Catalog
  alias MediaWatch.Catalog.Show
  alias MediaWatch.Parsing.Slice
  alias MediaWatch.Analysis.{Invitation, SliceUsage}
  alias __MODULE__, as: ShowOccurrence
  @required_fields [:title, :description, :airing_time, :slot_start, :slot_end]
  @optional_fields [:link, :show_id]
  @all_fields @required_fields ++ @optional_fields

  schema "show_occurrences" do
    belongs_to :show, Show, on_replace: :mark_as_invalid
    field :title, :string
    field :description, :string
    field :link, :string
    field :airing_time, :utc_datetime
    field :slot_start, :utc_datetime
    field :slot_end, :utc_datetime

    has_many :slice_usages, SliceUsage
    has_many :slices, through: [:slice_usages, :slice]

    has_many :invitations, Invitation
    has_many :guests, through: [:invitations, :person]
  end

  @doc false
  def changeset(occurrence \\ %ShowOccurrence{}, attrs) do
    occurrence
    |> cast(attrs, @all_fields)
    |> cast_assoc(:slice_usages, required: true)
    |> validate_required(@required_fields)
    |> unique_constraint([:show_id, :airing_time])
  end

  def get_occurrence_cs(
        slice = %Slice{id: id, type: :rss_entry, rss_entry: entry = %{pub_date: pub_date}},
        module
      ) do
    show_id = Catalog.get_show_id(slice.source_id)
    {start, end_} = module.get_time_slot(pub_date)

    changeset(%{
      show_id: show_id,
      title: entry.title,
      description: entry.description,
      link: entry.link,
      airing_time: pub_date |> module.get_airing_time() |> into_utc(),
      slot_start: start |> into_utc,
      slot_end: end_ |> into_utc,
      slice_usages: [%{slice_id: id, used: true}]
    })
  end

  def get_occurrence_change_cs(occ = %{slice_usages: existing}, used, discarded, new)
      when is_list(used) and is_list(discarded) and is_list(new) do
    used_ids = used |> Enum.map(& &1.id)

    to_update =
      existing
      |> Enum.map(fn curr ->
        curr |> SliceUsage.changeset(%{used: curr.slice_id in used_ids})
      end)

    new = new |> Enum.map(&SliceUsage.changeset(%{slice_id: &1.id, used: false}))

    occ
    |> change()
    |> put_assoc(:slice_usages, to_update ++ new)
  end

  def get_occurrence_at(datetime, module) do
    repo = module.get_repo()
    query = from(i in module.query(), select: i.id)

    from(o in ShowOccurrence, where: o.show_id in subquery(query) and o.airing_time == ^datetime)
    |> repo.one!
  end

  def query_slices_from_occurrence(occ = %ShowOccurrence{}),
    do:
      from(s in Slice,
        where: s.id in ^(occ.slices |> Enum.map(& &1.id)),
        preload: ^Slice.preloads()
      )

  def group_slices(occ, slices) do
    slices
    |> Enum.group_by(&get_status(&1, occ.slice_usages))
  end

  defp get_status(slice, all_slice_usages) do
    case all_slice_usages |> Enum.find(&(&1.slice_id == slice.id)) do
      nil -> :new
      %{used: false} -> :discarded
      %{used: true} -> :used
    end
  end

  def explain_error(
        {:error,
         cs = %{
           errors: [
             show_id:
               {_,
                [
                  constraint: :unique,
                  constraint_name: "show_occurrences_show_id_airing_time_index"
                ]}
           ]
         }},
        recurrent
      ) do
    with {_, airing_time} <- cs |> Ecto.Changeset.fetch_field(:airing_time),
         occ <- airing_time |> recurrent.get_occurrence_at() do
      {:error, {:unique_airing_time, occ}}
    else
      _ -> {:error, :unique_airing_time}
    end
  end

  def explain_error(
        {:error, %{errors: [airing_time: {_, [type: :utc_datetime, validation: :cast]}]}},
        _
      ),
      do: {:error, :no_airing_time_within_slot}

  def explain_error(res, _), do: res

  # Errors in date conversion are simply propagated as-is
  defp into_utc(e = {:error, _}), do: e
  defp into_utc(date), do: date |> Timex.Timezone.convert("UTC")
end
