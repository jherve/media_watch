defmodule MediaWatch.Analysis.ShowOccurrence.Invitation do
  use Ecto.Schema
  require Logger
  import Ecto.Changeset
  alias MediaWatch.Catalog.Person
  alias MediaWatch.Analysis.ShowOccurrence
  alias __MODULE__, as: Invitation

  schema "show_occurrences_invitations" do
    belongs_to :person, Person
    belongs_to :show_occurrence, ShowOccurrence
  end

  @doc false
  def changeset(invite \\ %Invitation{}, attrs) do
    invite
    |> cast(attrs, [])
    |> cast_assoc(:person, required: true)
    |> cast_assoc(:show_occurrence, required: true)
    |> unique_constraint([:person_id, :show_occurrence_id])
  end

  def get_guests_cs(occ, list_of_attrs) when is_list(list_of_attrs),
    do: list_of_attrs |> Enum.map(&changeset(%Invitation{show_occurrence: occ}, &1))

  def rescue_error(e = {:error, cs = %Ecto.Changeset{errors: errors}}, repo) do
    cond do
      error_in_person?(cs) -> cs |> rescue_error_on_person(repo)
      errors |> Enum.any?(&invitation_exists?/1) -> cs |> rescue_unique_error(repo)
      true -> e
    end
  end

  def rescue_error({:error, {:trigger, _, "show_occurrence_locked"}}, _), do: {:error, :locked}

  def rescue_error(e = {:error, _}, _), do: e

  defp invitation_exists?(
         {:person_id,
          {_,
           [
             constraint: :unique,
             constraint_name: "show_occurrences_invitations_person_id_show_occurrence_id_index"
           ]}}
       ),
       do: true

  defp invitation_exists?(_), do: false

  defp error_in_person?(%{changes: %{person: %{errors: errors}}})
       when is_list(errors) and errors != [],
       do: true

  defp error_in_person?(_), do: false

  defp rescue_error_on_person(cs = %Ecto.Changeset{changes: %{person: person_cs}}, repo) do
    with {_, occ} <- cs |> fetch_field(:show_occurrence),
         person when not is_nil(person) <- Person.get_existing_person_from_cs!(person_cs, repo) do
      {:error,
       {:person_exists, changeset(%Invitation{show_occurrence: occ, person: person}, %{})}}
    end
  end

  defp rescue_unique_error(cs, repo) do
    with {_, %{id: show_occurrence_id}} <- cs |> fetch_field(:show_occurrence),
         {_, %{id: person_id}} <- cs |> fetch_field(:person),
         invitation when not is_nil(invitation) <-
           Invitation |> repo.get_by(show_occurrence_id: show_occurrence_id, person_id: person_id),
         do: {:error, {:unique, invitation}}
  end
end
