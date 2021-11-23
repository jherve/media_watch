defmodule MediaWatch.Parsing.Slice do
  use Ecto.Schema
  import Ecto.Changeset
  alias Ecto.Multi
  alias MediaWatch.Catalog.Source
  alias MediaWatch.Parsing.ParsedSnapshot
  alias MediaWatch.Parsing.Slice.{RssEntry, RssChannelDescription, HtmlPreviewCard, OpenGraph}
  alias MediaWatch.Analysis.EntityRecognized

  alias __MODULE__, as: Slice
  @valid_types [:rss_entry, :rss_channel_description, :html_preview_card, :open_graph]
  @valid_kinds [:replay, :excerpt, :main_page]
  @required_fields [:type]
  @preloads [:rss_entry, :rss_channel_description, :entities]

  schema "slices" do
    field :type, Ecto.Enum, values: @valid_types
    field :kind, Ecto.Enum, values: @valid_kinds

    belongs_to :source, Source
    belongs_to :parsed_snapshot, ParsedSnapshot
    has_one :rss_entry, RssEntry, foreign_key: :id
    has_one :rss_channel_description, RssChannelDescription, foreign_key: :id
    has_one :html_preview_card, HtmlPreviewCard, foreign_key: :id
    has_one :open_graph, OpenGraph, foreign_key: :id
    has_many :entities, EntityRecognized

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
    |> cast_assoc(:html_preview_card)
    |> cast_assoc(:open_graph)
    |> set_type()
    |> validate_required(@required_fields)
    # SQLite adapter can not recognize the constraint that was violated, and the error reporting
    # is therefore a bit shaky and auto-magically guessed by ecto_sqlite3 (in some cases, badly)
    # (see https://hexdocs.pm/ecto_sqlite3/Ecto.Adapters.SQLite3.html#module-handling-foreign-key-constraints-in-changesets)
    #
    # Here, the constraint defined as "slices_rss_channel_descriptions_index" in the schema will
    # wrongfully be thrown as "slices_source_id_index", based on "source_id" field name. Since it
    # it the only constraint that applies on this field, it's an acceptable compromise to ignore
    # the actual constraint name.
    |> unique_constraint(:source_id)
  end

  def extract_date(%Slice{type: :rss_entry, rss_entry: %{pub_date: date}}), do: {:ok, date}
  def extract_date(%Slice{type: :rss_channel_description}), do: :error

  def extract_date(%Slice{type: :html_preview_card, html_preview_card: %{date: date}}),
    do: {:ok, date}

  def extract_date(%Slice{type: :open_graph}), do: :error

  def preloads(), do: @preloads

  def into_multi(cs_list) when is_list(cs_list) do
    cs_list
    |> Enum.with_index()
    |> Enum.reduce(Multi.new(), fn {cs, idx}, multi -> multi |> Multi.insert(idx, cs) end)
  end

  def get_error_reason(ok = {:ok, _obj}), do: ok

  # This is not the actual constraint name, see `changeset` for full explanation.
  def get_error_reason(
        {:error,
         e = %{
           errors: [
             source_id: {_, [constraint: :unique, constraint_name: "slices_source_id_index"]}
           ]
         }}
      ),
      do: {:unique, e}

  def get_error_reason(
        {:error,
         e = %{
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
      do: {:unique, e}

  def get_error_reason(
        {:error,
         e = %{
           errors: [],
           changes: %{
             html_preview_card: %{
               errors: [
                 title:
                   {_,
                    [
                      constraint: :unique,
                      constraint_name: "html_preview_cards_title_date_type_index"
                    ]}
               ]
             }
           }
         }}
      ),
      do: {:unique, e}

  def get_error_reason(e = {:error, _cs}), do: e

  def is_show_occurrence?(%Slice{type: type}), do: type in [:rss_entry, :html_preview_card]
  def is_description?(%Slice{type: type}), do: type in [:rss_channel_description, :open_graph]

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
