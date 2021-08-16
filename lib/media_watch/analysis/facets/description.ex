defmodule MediaWatch.Analysis.Facet.Description do
  use Ecto.Schema
  import Ecto.Changeset
  alias __MODULE__, as: Description

  schema "descriptions" do
    field :title, :string
    field :description, :string
    field :url, :string
    field :image, :string
  end

  @doc false
  def changeset(occurrence \\ %Description{}, attrs) do
    occurrence
    |> cast(attrs, [:title, :description, :url, :image])
  end
end
