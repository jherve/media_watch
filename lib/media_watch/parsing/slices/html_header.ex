defmodule MediaWatch.Parsing.Slice.HtmlHeader do
  use Ecto.Schema
  import Ecto.Changeset
  alias __MODULE__
  @required_fields [:title, :description]
  @optional_fields [:link, :image]
  @all_fields @required_fields ++ @optional_fields

  schema "html_headers" do
    field :title, :string
    field :description, :string
    field :link, :string
    field :image, :map
  end

  @doc false
  def changeset(header \\ %HtmlHeader{}, attrs) do
    header
    |> cast(attrs, @all_fields)
    |> validate_required(@required_fields)
  end
end
