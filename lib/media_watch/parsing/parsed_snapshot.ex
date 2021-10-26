defmodule MediaWatch.Parsing.ParsedSnapshot do
  @type t() :: %__MODULE__{
          __meta__: Ecto.Schema.Metadata.t(),
          id: integer() | nil,
          snapshot: MediaWatch.Snapshots.Snapshot.t() | nil,
          source: MediaWatch.Catalog.Source.t() | nil,
          data: map()
        }

  use Ecto.Schema
  import Ecto.Changeset
  alias MediaWatch.Catalog.Source
  alias MediaWatch.Snapshots.Snapshot
  alias MediaWatch.Parsing.Slice
  alias __MODULE__, as: ParsedSnapshot

  schema "parsed_snapshots" do
    belongs_to :snapshot, Snapshot
    belongs_to :source, Source
    field :data, :map

    Ecto.Schema.timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(parsed \\ %ParsedSnapshot{}, attrs) do
    parsed
    |> cast(attrs, [:id, :data])
    |> validate_required([:data])
    |> cast_assoc(:snapshot, required: true)
    |> cast_assoc(:source, required: true)
    |> unique_constraint(:snapshot_id)
  end

  def into_slice_cs(attrs, parsed = %ParsedSnapshot{snapshot: %{source: source}})
      when not is_nil(source) and not is_struct(source, Ecto.Association.NotLoaded) do
    Slice.changeset(%Slice{parsed_snapshot: parsed, source: source}, attrs)
  end

  def slice(parsed, module) do
    entries = get_entries(parsed) |> Enum.map(&module.into_slice_cs(%{rss_entry: &1}, parsed))

    description =
      %{rss_channel_description: get_channel_description(parsed)} |> module.into_slice_cs(parsed)

    entries ++ [description]
  end

  defp get_entries(%ParsedSnapshot{data: data, snapshot: %{type: :xml}}),
    do:
      data
      |> Map.get("entries")
      |> Enum.map(fn %{
                       "title" => title,
                       "description" => description,
                       "rss2:guid" => guid,
                       "rss2:link" => link,
                       "rss2:pubDate" => pub_date
                     } ->
        %{guid: guid, link: link, pub_date: pub_date, title: title, description: description}
      end)

  defp get_channel_description(%ParsedSnapshot{
         data: %{"description" => desc, "title" => title, "url" => url, "image" => image}
       }),
       do: %{
         "description" => desc,
         "title" => title,
         "link" => url,
         "image" => image
       }
end
