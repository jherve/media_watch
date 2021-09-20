defmodule MediaWatch.Parsing.Slice do
  use Ecto.Schema
  import Ecto.Changeset
  alias MediaWatch.Catalog.Source
  alias MediaWatch.Parsing.ParsedSnapshot
  alias MediaWatch.Parsing.Slice.{RssEntry, RssChannelDescription}
  alias __MODULE__, as: Slice
  @valid_types [:rss_entry, :rss_channel_description]
  @required_fields [:type]

  schema "slices" do
    field :type, Ecto.Enum, values: @valid_types

    belongs_to :source, Source
    belongs_to :parsed_snapshot, ParsedSnapshot
    has_one :rss_entry, RssEntry, foreign_key: :id
    has_one :rss_channel_description, RssChannelDescription, foreign_key: :id

    Ecto.Schema.timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(slice \\ %Slice{}, attrs) do
    slice
    |> cast(attrs, [:id])
    |> cast_assoc(:parsed_snapshot, required: true)
    |> cast_assoc(:source, required: true)
    |> cast_assoc(:rss_entry)
    |> cast_assoc(:rss_channel_description)
    |> set_type()
    |> validate_required(@required_fields)
    |> unique_constraint(:source_id, name: :slices_rss_channel_descriptions_index)
  end

  def get_error_reason({:ok, _obj}), do: :ok

  # TODO : for some reason (a bug in Ecto ?) the constraint name does not appear as
  # its actual name : "slices_rss_channel_descriptions_index" but with a name that appears
  # to be made-up by Ecto
  def get_error_reason(
        {:error,
         %{
           errors: [
             source_id:
               {_,
                [
                  constraint: :unique,
                  constraint_name: "slices_source_id_index"
                ]}
           ]
         }}
      ),
      do: :unique

  def get_error_reason(
        {:error,
         %{
           errors: [],
           changes: %{
             rss_entry: %{
               errors: [
                 guid: {_, [constraint: :unique, constraint_name: "rss_entries_guid_index"]}
               ]
             }
           }
         }}
      ),
      do: :unique

  def get_error_reason({:error, _cs}), do: :error

  defp set_type(cs) do
    case get_type(cs) do
      :error -> cs
      type -> cs |> put_change(:type, type)
    end
  end

  defp get_type(cs),
    do:
      @valid_types
      |> Enum.reduce_while(nil, fn field, _ ->
        if cs |> has_field?(field), do: {:halt, field}, else: {:cont, nil}
      end) || :error

  defp has_field?(cs, field) do
    case cs |> fetch_field(field) do
      {_, val} when not is_nil(val) -> true
      _ -> false
    end
  end
end
