defmodule MediaWatch.Parsing.ParsedSnapshot do
  @type t() :: %__MODULE__{
          __meta__: Ecto.Schema.Metadata.t(),
          id: integer() | nil,
          snapshot: MediaWatch.Snapshots.Snapshot.t() | nil,
          data: map()
        }

  use Ecto.Schema
  import Ecto.Changeset
  alias MediaWatch.Snapshots.Snapshot
  alias MediaWatch.Parsing.Slice
  alias __MODULE__, as: ParsedSnapshot
  @primary_key false

  schema "parsed_snapshots" do
    belongs_to :snapshot, Snapshot, foreign_key: :id, primary_key: true
    field :data, :map

    Ecto.Schema.timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(parsed \\ %ParsedSnapshot{}, attrs) do
    parsed
    |> cast(attrs, [:id, :data])
    |> validate_required([:data])
    |> cast_assoc(:snapshot, required: true)
    |> unique_constraint(:id)
  end

  def slice(parsed), do: get_entries(parsed) ++ [get_channel_description(parsed)]

  defp get_entries(parsed = %ParsedSnapshot{data: data, snapshot: %{source: source, xml: xml}})
       when not is_nil(source) and not is_nil(xml),
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
           Slice.changeset(%Slice{parsed_snapshot: parsed, source: source}, %{
             rss_entry: %{
               guid: guid,
               link: link,
               pub_date: pub_date,
               title: title,
               description: description
             }
           })
         end)

  defp get_channel_description(
         parsed = %ParsedSnapshot{
           data: %{
             "description" => desc,
             "title" => title,
             "url" => url,
             "image" => image
           },
           snapshot: %{source: source}
         }
       ),
       do:
         Slice.changeset(%Slice{parsed_snapshot: parsed, source: source}, %{
           rss_channel_description: %{
             "description" => desc,
             "title" => title,
             "link" => url,
             "image" => image
           }
         })

  defmacro __using__(_opts) do
    quote do
      use MediaWatch.Parsing.Sliceable

      @impl true
      defdelegate slice(parsed), to: MediaWatch.Parsing.ParsedSnapshot

      defoverridable slice: 1
    end
  end
end
