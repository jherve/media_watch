defmodule MediaWatch.Catalog.Podcast do
  use Ecto.Schema
  import Ecto.Changeset
  alias MediaWatch.Catalog.Item
  alias __MODULE__, as: Podcast

  schema "watched_podcasts" do
    field :name, :string
    field :url, :string
    belongs_to :item, Item, foreign_key: :id, define_field: false
  end

  @doc false
  def changeset(podcast \\ %Podcast{item: %Item{id: nil}}, attrs) do
    podcast
    |> cast(attrs, [:name, :url])
    |> cast_assoc(:item)
    |> validate_required([:name, :url])
    |> unique_constraint([:name, :url])
  end
end
