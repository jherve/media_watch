defmodule MediaWatch.Catalog.Show do
  use Ecto.Schema
  import Ecto.Changeset
  alias MediaWatch.Catalog.Item
  alias MediaWatch.Analysis.ShowOccurrence
  alias __MODULE__, as: Show
  @required_fields [:name, :url, :airing_schedule, :duration_minutes]
  @all_fields @required_fields

  schema "watched_shows" do
    field :name, :string
    field :url, :string
    field :airing_schedule, Crontab.CronExpression.Ecto.Type
    field :duration_minutes, :integer

    belongs_to :item, Item, foreign_key: :id, define_field: false
    has_many :occurrences, ShowOccurrence
  end

  @doc false
  def changeset(show \\ %Show{}, attrs) do
    show
    |> cast(attrs, @all_fields)
    |> validate_required(@required_fields)
    |> unique_constraint([:name, :url])
  end
end
