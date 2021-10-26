defmodule MediaWatch.Analysis.ShowOccurrence.Detail do
  use Ecto.Schema
  import Ecto.Changeset
  alias MediaWatch.Analysis.ShowOccurrence
  alias __MODULE__, as: Detail
  @primary_key false
  @required_fields [:title, :description, :id]
  @optional_fields [:link]
  @all_fields @required_fields ++ @optional_fields

  schema "show_occurrences_details" do
    belongs_to :show_occurrence, ShowOccurrence, foreign_key: :id, primary_key: true
    field :title, :string
    field :description, :string
    field :link, :string
  end

  @doc false
  def changeset(detail \\ %Detail{}, attrs) do
    detail
    |> cast(attrs, @all_fields)
    |> cast_assoc(:show_occurrence)
    |> validate_required(@required_fields)
    |> unique_constraint(:id)
  end

  def explain_create_error(
        {:error,
         cs = %{
           errors: [
             id:
               {_,
                [
                  constraint: :unique,
                  constraint_name: "show_occurrences_details_id_index"
                ]}
           ]
         }},
        repo
      ) do
    with {_, id} <- cs |> fetch_field(:id),
         detail when not is_nil(detail) <- Detail |> repo.get(id),
         do: {:error, {:unique, detail}}
  end

  def explain_create_error(ok_or_other_error, _), do: ok_or_other_error
end
