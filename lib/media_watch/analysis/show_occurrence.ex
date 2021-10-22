defmodule MediaWatch.Analysis.ShowOccurrence do
  use Ecto.Schema
  import Ecto.Changeset
  alias MediaWatch.Catalog.Show
  alias MediaWatch.Analysis.{ShowOccurrence.Invitation, SliceUsage}
  alias __MODULE__, as: ShowOccurrence
  @required_fields [:airing_time, :slot_start, :slot_end, :show_id]
  @optional_fields []
  @all_fields @required_fields ++ @optional_fields

  schema "show_occurrences" do
    belongs_to :show, Show, on_replace: :mark_as_invalid
    field :airing_time, :utc_datetime
    field :slot_start, :utc_datetime
    field :slot_end, :utc_datetime

    has_one :detail, ShowOccurrence.Detail, foreign_key: :id

    has_many :slice_usages, SliceUsage
    has_many :slices, through: [:slice_usages, :slice]

    has_many :invitations, Invitation
    has_many :guests, through: [:invitations, :person]
  end

  @doc false
  def changeset(occurrence \\ %ShowOccurrence{}, attrs) do
    occurrence
    |> cast(attrs, @all_fields)
    |> cast_assoc(:slice_usages)
    |> validate_required(@required_fields)
    |> unique_constraint([:show_id, :airing_time])
  end
end
