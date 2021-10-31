defmodule MediaWatch.Catalog.Source.WebIndexPage do
  @type t() :: %__MODULE__{
          __meta__: Ecto.Schema.Metadata.t(),
          id: integer() | nil,
          url: binary()
        }

  use Ecto.Schema
  import Ecto.Changeset
  alias MediaWatch.Http
  alias __MODULE__

  schema "catalog_web_index_pages" do
    field :url, :string
  end

  @doc false
  def changeset(web_index_page \\ %WebIndexPage{}, attrs) do
    web_index_page
    |> cast(attrs, [:url])
    |> validate_required([:url])
    |> unique_constraint([:url])
  end

  def into_snapshot_attrs(%WebIndexPage{url: url}),
    do:
      with(
        {:ok, content} <- Http.get_body(url),
        do: {:ok, %{url: url, html: %{content: content}}}
      )

  def parse(content) when is_binary(content), do: content |> Floki.parse_document()
end
