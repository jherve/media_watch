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

  def explain_error(cs = %Ecto.Changeset{errors: errors}) do
    if errors |> Enum.any?(&has_same_content?/1), do: :unique_content, else: cs
  end

  defp has_same_content?(
         {:content, {_, [constraint: :unique, constraint_name: "snapshots_html_content_index"]}}
       ),
       do: true

  defp has_same_content?(_), do: false
end
