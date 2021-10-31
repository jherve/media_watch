defmodule MediaWatch.Parsing.Slice.HtmlPreviewCard do
  use Ecto.Schema
  import Ecto.Changeset
  alias __MODULE__
  @required_fields [:title, :date, :type]
  @optional_fields [:text, :link, :image]
  @all_fields @required_fields ++ @optional_fields
  @valid_types [:replay, :excerpt, :excerpt_short, :article, :reference_page]

  schema "html_preview_cards" do
    field :title, :string
    field :text, :string
    field :type, Ecto.Enum, values: @valid_types
    field :link, :string
    field :image, :map
    field :date, :utc_datetime
  end

  @doc false
  def changeset(card \\ %HtmlPreviewCard{}, attrs) do
    card
    |> cast(attrs, @all_fields)
    |> validate_required(@required_fields)
    |> unique_constraint([:title, :date, :type])
  end
end
