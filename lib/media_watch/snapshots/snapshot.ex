defmodule MediaWatch.Snapshots.Snapshot do
  @type t() :: %__MODULE__{
          __meta__: Ecto.Schema.Metadata.t(),
          id: integer() | nil,
          type: atom(),
          source: MediaWatch.Catalog.Source.t() | nil,
          xml: MediaWatch.Snapshots.Snapshot.Xml.t() | nil,
          html: MediaWatch.Snapshots.Snapshot.Html.t() | nil
        }

  use Ecto.Schema
  import Ecto.Changeset
  alias MediaWatch.Catalog.Source
  alias MediaWatch.Snapshots.Snapshot.{Xml, Html}
  alias __MODULE__, as: Snapshot
  @required_fields [:type, :url, :content_hash]
  @preloads [:source, :xml, :html]

  schema "snapshots" do
    field :url, :string
    field :type, Ecto.Enum, values: [:xml, :html]
    field :content_hash, :string

    belongs_to :source, Source
    has_one :xml, Xml, foreign_key: :id
    has_one :html, Html, foreign_key: :id

    Ecto.Schema.timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(snapshot \\ %Snapshot{}, attrs) do
    snapshot
    |> cast(attrs, [:id, :url])
    |> cast_assoc(:source, required: true)
    |> cast_assoc(:xml)
    |> cast_assoc(:html)
    |> set_type()
    |> set_hash()
    |> validate_required(@required_fields)
    |> unique_constraint([:source_id, :content_hash])
  end

  def preloads(), do: @preloads

  def explain_error(e = {:error, %Ecto.Changeset{errors: errors}}) do
    if errors |> Enum.any?(&has_same_content?/1), do: {:error, :unique_content}, else: e
  end

  defp has_same_content?(
         {:source_id,
          {_, [constraint: :unique, constraint_name: "snapshots_source_id_content_hash_index"]}}
       ),
       do: true

  defp has_same_content?(_), do: false

  defp set_type(cs) do
    cond do
      has_field?(cs, :xml) -> cs |> put_change(:type, :xml)
      has_field?(cs, :html) -> cs |> put_change(:type, :html)
      true -> cs
    end
  end

  defp has_field?(cs, field) do
    case cs |> fetch_field(field) do
      {_, val} when not is_nil(val) -> true
      _ -> false
    end
  end

  defp set_hash(cs) do
    content =
      case cs |> apply_changes() do
        %{xml: %{content: content}} -> content
        %{html: %{content: content}} -> content
      end

    cs |> put_change(:content_hash, md5sum(content))
  end

  defp md5sum(data), do: :crypto.hash(:md5, data |> :erlang.term_to_binary()) |> Base.encode64()
end
