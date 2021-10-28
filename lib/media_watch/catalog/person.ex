defmodule MediaWatch.Catalog.Person do
  use Ecto.Schema
  import Ecto.Changeset
  alias MediaWatch.Wikidata
  alias __MODULE__, as: Person
  @required_fields [:label]
  @optional_fields [:wikidata_qid, :description]
  @all_fields @required_fields ++ @optional_fields

  schema "persons" do
    field :wikidata_qid, :id
    field :label, :string
    field :description, :string
  end

  @doc false
  def changeset(person \\ %Person{}, attrs) do
    person
    |> cast(attrs, @all_fields)
    |> update_from_wikidata()
    |> validate_required(@required_fields)
    |> unique_constraint([:wikidata_qid])
    |> unique_constraint([:label])
  end

  def get_existing_person_from_cs(
        cs = %{
          errors: [label: {_, [constraint: :unique, constraint_name: "persons_label_index"]}]
        },
        repo
      ) do
    with {_, label} <- cs |> fetch_field(:label), do: Person |> repo.get_by(label: label)
  end

  def get_existing_person_from_cs(
        cs = %{
          errors: [
            wikidata_qid:
              {_, [constraint: :unique, constraint_name: "persons_wikidata_qid_index"]}
          ]
        },
        repo
      ) do
    with {_, qid} <- cs |> fetch_field(:wikidata_qid),
         do: Person |> repo.get_by(wikidata_qid: qid)
  end

  defp update_from_wikidata(cs) do
    with {_, label} <- cs |> fetch_field(:label),
         data when is_map(data) <- Wikidata.get_info_from_name(label) do
      cs
      |> put_change(:wikidata_qid, data.id)
      |> put_change(:description, data.description)
      |> put_change(:label, data.label)
    else
      _ -> cs
    end
  end
end
