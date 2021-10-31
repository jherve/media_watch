defmodule MediaWatch.Snapshots.Snapshot.Html do
  @type t() :: %__MODULE__{
          __meta__: Ecto.Schema.Metadata.t(),
          id: integer() | nil,
          content: binary()
        }

  use Ecto.Schema
  import Ecto.Changeset
  alias MediaWatch.Catalog.Source.WebIndexPage
  alias __MODULE__

  schema "snapshots_html" do
    field :content, :string
  end

  @doc false
  def changeset(html \\ %Html{}, attrs) do
    html
    |> cast(attrs, [:content])
    |> validate_required([:content])
    |> unique_constraint(:content)
  end

  def parse_snapshot(%Html{content: content}), do: content |> WebIndexPage.parse()
end
