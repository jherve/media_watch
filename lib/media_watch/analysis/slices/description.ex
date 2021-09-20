defmodule MediaWatch.Analysis.Slice.Description do
  use Ecto.Schema
  import Ecto.Changeset
  alias __MODULE__, as: Description
  @all_fields [:title, :description, :url, :image]
  @required_fields @all_fields

  schema "descriptions" do
    field :title, :string
    field :description, :string
    field :url, :string
    field :image, :string
  end

  @doc false
  def changeset(occurrence \\ %Description{}, attrs) do
    occurrence
    |> cast(attrs, @all_fields)
    |> validate_required(@required_fields)
  end
end
