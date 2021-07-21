defmodule MediaWatch.Catalog.Show do
  use Ecto.Schema
  import Ecto.Changeset
  alias MediaWatch.Catalog.Item
  alias __MODULE__, as: Show

  schema "watched_shows" do
    field :name, :string
    field :url, :string
    belongs_to :item, Item, foreign_key: :id, define_field: false
  end

  @doc false
  def changeset(show \\ %Show{}, attrs) do
    show
    |> cast(attrs, [:name, :url])
    |> validate_required([:name, :url])
    |> unique_constraint([:name, :url])
  end
end
