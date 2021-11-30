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

    Ecto.Schema.timestamps(type: :utc_datetime)
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

  def get_existing_person_from_cs!(cs = %Ecto.Changeset{errors: errors}, repo) do
    cond do
      errors |> Enum.any?(&has_unique_label?/1) ->
        with {_, label} <- cs |> fetch_field(:label), do: Person |> repo.get_by(label: label)

      errors |> Enum.any?(&has_unique_qid?/1) ->
        with {_, qid} <- cs |> fetch_field(:wikidata_qid),
             do: Person |> repo.get_by(wikidata_qid: qid)

      true ->
        raise "Person changeset does not contain enough information"
    end
  end

  defp has_unique_label?(
         {:label, {_, [constraint: :unique, constraint_name: "persons_label_index"]}}
       ),
       do: true

  defp has_unique_label?(_), do: false

  defp has_unique_qid?(
         {:wikidata_qid,
          {_, [constraint: :unique, constraint_name: "persons_wikidata_qid_index"]}}
       ),
       do: true

  defp has_unique_qid?(_), do: false

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
