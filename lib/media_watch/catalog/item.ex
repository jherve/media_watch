defmodule MediaWatch.Catalog.Item do
  use Ecto.Schema
  import Ecto.Changeset
  alias __MODULE__, as: Item

  schema "watched_items" do
  end

  @doc false
  def changeset(item \\ %Item{}, attrs) do
    item
    |> cast(attrs, [:id])
  end
end
