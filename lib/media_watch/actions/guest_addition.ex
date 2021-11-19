defmodule MediaWatch.Actions.GuestAddition do
  use Ecto.Schema
  import Ecto.Changeset
  alias MediaWatch.Analysis.ShowOccurrence
  alias MediaWatch.Analysis.ShowOccurrence.Invitation
  alias __MODULE__
  @primary_key false

  embedded_schema do
    belongs_to :show_occurrence, ShowOccurrence
    field :person_label, :string
  end

  @doc false
  def changeset(guest_add \\ %GuestAddition{}, attrs) do
    guest_add
    |> cast(attrs, [:person_label])
    |> cast_assoc(:show_occurrence, required: true)
    |> validate_required([:person_label])
  end

  def to_invitation_cs(cs = %Ecto.Changeset{data: %GuestAddition{}, valid?: true}) do
    {:ok,
     %Invitation{
       show_occurrence: cs |> fetch_field!(:show_occurrence)
     }
     |> Invitation.changeset(%{person: %{label: cs |> fetch_change!(:person_label)}})}
  end

  def to_invitation_cs(cs = %Ecto.Changeset{data: %GuestAddition{}, valid?: false}),
    do: {:error, cs}
end
