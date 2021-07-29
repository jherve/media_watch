defmodule MediaWatch.Analysis.Facet.ShowOccurrence do
  use Ecto.Schema
  import Ecto.Changeset
  alias __MODULE__, as: ShowOccurrence

  schema "show_occurrences" do
    field :title, :string
    field :description, :string
    field :url, :string
  end

  @doc false
  def changeset(occurrence \\ %ShowOccurrence{}, attrs) do
    occurrence
    |> cast(attrs, [:title, :description, :url])
  end
end
