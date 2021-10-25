defmodule MediaWatch.Analysis.ShowOccurrence.Invitation do
  use Ecto.Schema
  require Logger
  import Ecto.Changeset
  alias MediaWatch.Repo
  alias MediaWatch.Catalog.Person
  alias MediaWatch.Analysis.{ShowOccurrence, EntitiesClassification}
  alias __MODULE__, as: Invitation
  @primary_key false

  schema "show_occurrences_invitations" do
    belongs_to :person, Person, primary_key: true
    belongs_to :show_occurrence, ShowOccurrence, primary_key: true
  end

  @doc false
  def changeset(invite \\ %Invitation{}, attrs) do
    invite
    |> cast(attrs, [])
    |> cast_assoc(:person, required: true)
    |> cast_assoc(:show_occurrence, required: true)
    |> unique_constraint([:person_id, :show_occurrence_id])
  end

  def get_guests_attrs(list, hosted) when is_list(list),
    do: list |> Enum.map(&get_guests_attrs(&1, hosted))

  def get_guests_attrs(%ShowOccurrence{slice_usages: usages}, hosted) do
    entities =
      usages |> organize_entities |> EntitiesClassification.cleanup() |> reject_hosts(hosted)

    entities
    |> EntitiesClassification.get_guests()
    |> EntitiesClassification.pick_candidates()
    |> Enum.map(&%{person: %{label: &1}})
  end

  defp organize_entities(slice_usages),
    do:
      slice_usages
      |> Enum.map(&{&1.slice, &1.type})
      |> Enum.flat_map(fn {%{entities: entities}, type} ->
        entities |> Enum.map(&%{label: &1.label, type: type, field: &1.field})
      end)

  defp reject_hosts(entities, hosted) do
    hosts = get_all_hosts(hosted)
    entities |> Enum.reject(&(&1.label in hosts))
  end

  def get_all_hosts(hosted) do
    hosted.get_hosts() ++
      if(function_exported?(hosted, :get_alternate_hosts, 0),
        do: hosted.get_alternate_hosts(),
        else: []
      ) ++
      if(function_exported?(hosted, :get_columnists, 0),
        do: hosted.get_columnists(),
        else: []
      )
  end

  def get_guests_cs(occ, list_of_attrs) when is_list(list_of_attrs),
    do: list_of_attrs |> Enum.map(&changeset(%Invitation{show_occurrence: occ}, &1))

  def insert_guests(cs_list) when is_list(cs_list),
    do: cs_list |> Enum.map(&insert_guest/1)

  def insert_guest(cs) when is_struct(cs, Ecto.Changeset),
    do: cs |> Repo.insert_and_retry() |> handle_error()

  defp handle_error(ok = {:ok, _}), do: ok

  # Handle the case when the person already exists
  defp handle_error({:error, cs = %{changes: %{person: person_cs = %{errors: errors}}}})
       when is_list(errors) and errors != [] do
    with {_, occ} <- cs |> fetch_field(:show_occurrence),
         person <- Person.get_existing_person_from_cs(person_cs) do
      changeset(%Invitation{show_occurrence: occ, person: person}, %{})
      |> insert_guest()
    end
  end

  # Handle the case when the invitation already exists
  defp handle_error(
         e =
           {:error,
            %{
              errors: [
                person_id:
                  {_,
                   [
                     constraint: :unique,
                     constraint_name:
                       "show_occurrences_invitations_person_id_show_occurrence_id_index"
                   ]}
              ]
            }}
       ) do
    e
  end
end
