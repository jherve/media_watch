defmodule MediaWatch.Catalog.Item do
  use Ecto.Schema
  import Ecto.Changeset
  alias __MODULE__, as: Item
  alias MediaWatch.Catalog.Podcast

  schema "watched_items" do
    has_one :podcast, Podcast, foreign_key: :id
  end

  @doc false
  def changeset(item \\ %Item{}, attrs) do
    item
    |> cast(attrs, [:id])
    |> cast_assoc(:podcast)
    |> validate_required_inclusion([:podcast])
  end

  def validate_required_inclusion(changeset, fields) do
    if Enum.any?(fields, &present?(changeset, &1)) do
      changeset
    else
      # Add the error to the first field only since Ecto requires a field name for each error.
      add_error(changeset, hd(fields), "One of these fields must be present: #{inspect(fields)}")
    end
  end

  def present?(changeset, field) do
    case changeset |> fetch_field(field) do
      {_, val} when not is_nil(val) -> true
      {_, nil} -> false
    end
  end
end
