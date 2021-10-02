defmodule MediaWatch.Parsing.Slice do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query
  alias MediaWatch.Catalog
  alias MediaWatch.Catalog.Source
  alias MediaWatch.Parsing.ParsedSnapshot
  alias MediaWatch.Parsing.Slice.{RssEntry, RssChannelDescription}
  alias MediaWatch.Analysis.{Description, ShowOccurrence}

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
    |> unsafe_unique_constraint()
    |> unique_constraint(:source_id, name: :slices_rss_channel_descriptions_index)
  end

  def create_description(slice = %Slice{}) do
    item_id = Catalog.get_item_id(slice.source_id)
    Description.from(slice, item_id)
  end

  def create_occurrence(slice = %Slice{}) do
    show_id = Catalog.get_show_id(slice.source_id)
    ShowOccurrence.from(slice, show_id)
  end

  def update_occurrence(occ, slice),
    do:
      occ
      |> ShowOccurrence.changeset(%{slices_discarded: occ.slices_discarded ++ [slice.id]})

  def get_error_reason({:ok, _obj}), do: :ok

  def get_error_reason(
        {:error,
         %{
           errors: [
             source_id:
               {_,
                [
                  constraint: :unique,
                  constraint_name: "slices_rss_channel_descriptions_index"
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

  def get_error_reason(
        {:error, %{errors: [source_id: {_, [validation: :unsafe_unique_description]}]}}
      ),
      do: :unique

  def get_error_reason(
        {:error, %{errors: [rss_entry: {_, [validation: :unsafe_unique_entry_pub_date]}]}}
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

  # SQLite adapter can not recognize the constraint that was violated, and the error reporting
  # is therefore a bit shaky and auto-magically guessed by ecto_sqlite3 (in some cases, badly)
  # (see https://hexdocs.pm/ecto_sqlite3/Ecto.Adapters.SQLite3.html#module-handling-foreign-key-constraints-in-changesets)
  # To prevent this, we use this function that checks beforehand whether a conflicting record
  # already exists in the db (inspired by Ecto's unsafe_validate_unique that does not work
  # properly with FK fields). This allows proper error detection, and the constraint is checked
  # by the database anyway (but most likely it will be more difficult to recover)
  defp unsafe_unique_constraint(cs) do
    case cs |> fetch_field(:type) do
      {_, :rss_channel_description} -> cs |> unsafe_unique_description()
      {_, :rss_entry} -> cs |> unsafe_unique_entry_pub_date()
    end
  end

  defp unsafe_unique_description(cs) do
    with {_, %{id: id}} <- cs |> fetch_field(:source) do
      query = from(s in Slice, where: s.source_id == ^id)

      if query |> MediaWatch.Repo.exists?(),
        do:
          cs
          |> add_error(:source_id, "has already been taken",
            validation: :unsafe_unique_description
          ),
        else: cs
    end
  end

  defp unsafe_unique_entry_pub_date(cs) do
    with {_, %{id: id}} <- cs |> fetch_field(:source),
         {_, %{pub_date: pub_date}} <- cs |> fetch_field(:rss_entry) do
      query =
        from(s in Slice,
          join: r in RssEntry,
          on: r.id == s.id,
          where: s.source_id == ^id and r.pub_date == ^pub_date
        )

      if query |> MediaWatch.Repo.exists?(),
        do:
          cs
          |> add_error(:rss_entry, "has already been taken",
            validation: :unsafe_unique_entry_pub_date
          ),
        else: cs
    end
  end
end
