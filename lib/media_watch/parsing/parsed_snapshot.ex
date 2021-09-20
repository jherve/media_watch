defmodule MediaWatch.Parsing.ParsedSnapshot do
  @behaviour MediaWatch.Analysis.Sliceable
  use Ecto.Schema
  import Ecto.Changeset
  alias MediaWatch.Snapshots.Snapshot
  alias MediaWatch.Analysis.Slice
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

  def slice(parsed), do: [get_channel_description(parsed)]

  defp get_entries(parsed = %ParsedSnapshot{data: data, snapshot: %{source: source, xml: xml}})
       when not is_nil(source) and not is_nil(xml),
       do:
         data
         |> Map.get("entries")
         |> Enum.map(fn entry ->
           Slice.changeset(%Slice{parsed_snapshot: parsed, source: source}, %{
             show_occurrence: entry
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
end
