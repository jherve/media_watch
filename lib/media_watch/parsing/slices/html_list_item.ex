defmodule MediaWatch.Parsing.Slice.HtmlListItem do
  use Ecto.Schema
  import Ecto.Changeset
  alias __MODULE__
  @required_fields [:title, :date]
  @optional_fields [:text, :link, :image]
  @all_fields @required_fields ++ @optional_fields

  schema "html_list_items" do
    field :title, :string
    field :text, :string
    field :link, :string
    field :image, :map
    field :date, :utc_datetime
  end

  @doc false
  def changeset(item \\ %HtmlListItem{}, attrs) do
    item
    |> cast(attrs, @all_fields)
    |> validate_required(@required_fields)
    |> unique_constraint([:title, :date])
  end
end
