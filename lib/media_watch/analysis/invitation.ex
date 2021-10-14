defmodule MediaWatch.Analysis.Invitation do
  use Ecto.Schema
  import Ecto.Changeset
  alias MediaWatch.Catalog.Person
  alias MediaWatch.Analysis.ShowOccurrence
  alias __MODULE__, as: Invitation
  @primary_key false

  schema "invitations" do
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

  def insert_guests_from(occ, repo, recognisable) do
    if function_exported?(recognisable, :get_guests_attrs, 1) do
      apply(recognisable, :get_guests_attrs, [occ])
      |> then(&get_guests_cs(occ, &1))
      |> then(&insert_guests(&1, repo))
    else
      []
    end
  end

  def get_guests_cs(occ, list_of_attrs) when is_list(list_of_attrs),
    do: list_of_attrs |> Enum.map(&changeset(%Invitation{show_occurrence: occ}, &1))

  def insert_guests(cs_list, repo) when is_list(cs_list),
    do: cs_list |> Enum.map(&insert_guest(&1, repo))

  def insert_guest(cs, repo) when is_struct(cs, Ecto.Changeset),
    do: cs |> MediaWatch.Repo.insert_and_retry(repo) |> handle_error(repo)

  defp handle_error(ok = {:ok, _}, _), do: ok

  # Handle the case when the person already exists
  defp handle_error(
         {:error, cs = %{changes: %{person: person_cs = %{errors: errors}}}},
         repo
       )
       when is_list(errors) and errors != [] do
    with {_, occ} <- cs |> fetch_field(:show_occurrence),
         person <- Person.get_existing_person_from_cs(person_cs, repo) do
      changeset(%Invitation{show_occurrence: occ, person: person}, %{})
      |> insert_guest(repo)
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
                     constraint_name: "invitations_person_id_show_occurrence_id_index"
                   ]}
              ]
            }},
         _repo
       ) do
    e
  end
end
