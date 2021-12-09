defmodule MediaWatch.Analysis.ShowOccurrence do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query
  alias Ecto.Multi
  alias MediaWatch.Catalog.Show
  alias MediaWatch.Analysis.{ShowOccurrence.Invitation, SliceUsage}
  alias __MODULE__, as: ShowOccurrence
  @required_fields [:airing_time, :show_id]
  @optional_fields []
  @all_fields @required_fields ++ @optional_fields

  schema "show_occurrences" do
    belongs_to :show, Show, on_replace: :mark_as_invalid
    field :airing_time, :utc_datetime
    field :manual_edited?, :boolean

    has_one :detail, ShowOccurrence.Detail, foreign_key: :id

    has_many :slice_usages, SliceUsage
    has_many :slices, through: [:slice_usages, :slice]

    has_many :invitations, Invitation
    has_many :guests, through: [:invitations, :person]

    Ecto.Schema.timestamps(type: :utc_datetime)
  end

  @doc false
  def create_changeset(attrs) do
    %ShowOccurrence{}
    |> cast(attrs, @all_fields)
    |> cast_assoc(:slice_usages)
    |> validate_required(@required_fields)
    |> unique_constraint([:show_id, :airing_time])
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
        repo
      ) do
    with {_, airing_time} <- cs |> fetch_field(:airing_time),
         {_, show_id} <- cs |> fetch_field(:show_id),
         occ when not is_nil(occ) <-
           ShowOccurrence |> repo.get_by(airing_time: airing_time, show_id: show_id),
         do: {:error, {:unique, occ}}
  end

  def explain_error(ok_or_other_error, _), do: ok_or_other_error

  def into_manual_multi(multi = %Multi{}, show_occurrence_id) do
    query = from(so in ShowOccurrence, where: so.id == ^show_occurrence_id)

    unlock_multi(query)
    |> Multi.append(multi)
    |> Multi.append(lock_multi(query))
  end

  defp unlock_multi(query),
    do: Multi.new() |> Multi.update_all(:unlock, query, set: [manual_edited?: false])

  defp lock_multi(query),
    do: Multi.new() |> Multi.update_all(:lock, query, set: [manual_edited?: true])
end
