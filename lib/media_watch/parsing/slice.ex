defmodule MediaWatch.Parsing.Slice do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query
  alias MediaWatch.Catalog.Source
  alias MediaWatch.Parsing.ParsedSnapshot
  alias MediaWatch.Parsing.Slice.{RssEntry, RssChannelDescription}

  alias __MODULE__, as: Slice
  @valid_types [:rss_entry, :rss_channel_description]
  @required_fields [:type]
  @preloads [:rss_entry, :rss_channel_description]

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

  def extract_date(%Slice{type: :rss_entry, rss_entry: %{pub_date: date}}), do: {:ok, date}
  def extract_date(%Slice{}), do: :error

  def preloads(), do: @preloads

  @doc """
  Insert all the slices contained in `cs_list`, discarding 'unique' errors.

  The operation occurs in an single translation, with the guarantee that
  all the valid slices either have been inserted or are already present in the
  database.
  """
  def insert_all(cs_map, repo, failures_so_far \\ %{})

  def insert_all(cs_map, _repo, failures_so_far) when cs_map == %{},
    do: {:error, [], [], failures_so_far |> Map.values()}

  def insert_all(cs_map, repo, failures_so_far) when is_map(cs_map) do
    case cs_map |> run_and_group_results(repo) do
      {:error, _, _, failures} ->
        # In case of a rollback, the transaction is attempted again, with all
        # the steps that led to an error removed.
        failed_steps = failures |> Map.keys()

        cs_map
        |> Enum.reject(fn {k, _} -> k in failed_steps end)
        |> Map.new()
        |> insert_all(repo, failures_so_far |> Map.merge(failures))

      {:ok, ok, unique} ->
        if failures_so_far |> Enum.empty?(),
          do: {:ok, ok |> Map.values(), unique |> Map.values()},
          else:
            {:error, ok |> Map.values(), unique |> Map.values(), failures_so_far |> Map.values()}
    end
  end

  defp run_and_group_results(cs_map, repo),
    do:
      cs_map
      |> into_multi()
      |> repo.transaction()
      |> group_multi_results()

  defp into_multi(cs_map) do
    alias Ecto.Multi

    cs_map
    |> Enum.reduce(Multi.new(), fn {name, cs}, multi ->
      multi
      |> Multi.run(name, fn repo, _ ->
        # All the operations within the transaction are assumed to be 'successful'
        # whatever their actual result, so that the whole transaction can complete.
        case MediaWatch.Repo.insert_and_retry(cs, repo) |> get_error_reason() do
          u = {:unique, _val} -> {:ok, u}
          e = {:error, _} -> {:ok, e}
          ok = {:ok, _} -> ok
        end
      end)
    end)
    |> Multi.run(:control_stage, &fail_if_any_failure/2)
  end

  defp fail_if_any_failure(_repo, changes) do
    # If there is any actual error within the transaction's operations, the
    # final stage enforces a rollback.
    failures = changes |> Enum.filter(&match?({_, {:error, _}}, &1)) |> Map.new()
    if not (failures |> Enum.empty?()), do: {:error, nil}, else: {:ok, nil}
  end

  defp group_multi_results({:error, :control_stage, nil, changes}) do
    res =
      changes
      |> Enum.group_by(&categorize_errors/1)
      |> Map.new(fn {k, v} -> {k, v |> Map.new()} end)

    {:error, res |> Map.get(:ok, %{}), res |> Map.get(:unique, %{}), res |> Map.get(:error, %{})}
  end

  defp group_multi_results({:ok, changes}) do
    res =
      changes
      |> Map.drop([:control_stage])
      |> Enum.group_by(&categorize_errors/1)
      |> Map.new(fn {k, v} -> {k, v |> Map.new()} end)

    {:ok, res |> Map.get(:ok, %{}), res |> Map.get(:unique, %{})}
  end

  defp categorize_errors({_k, {:unique, _v}}), do: :unique
  defp categorize_errors({_k, {:error, _v}}), do: :error
  defp categorize_errors({_k, _v}), do: :ok

  defp get_error_reason(ok = {:ok, _obj}), do: ok

  defp get_error_reason(
         {:error,
          e = %{
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
       do: {:unique, e}

  defp get_error_reason(
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

  defp get_error_reason(
         {:error, e = %{errors: [source_id: {_, [validation: :unsafe_unique_description]}]}}
       ),
       do: {:unique, e}

  defp get_error_reason(
         {:error, e = %{errors: [rss_entry: {_, [validation: :unsafe_unique_entry_pub_date]}]}}
       ),
       do: {:unique, e}

  defp get_error_reason(e = {:error, _cs}), do: e

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
