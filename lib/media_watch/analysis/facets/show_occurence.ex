defmodule MediaWatch.Analysis.Facets.ShowOccurrence do
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

  def slice(parsed = %{data: data}) do
    data |> Map.get("entries") |> Enum.map(&changeset/1)
  end
end
