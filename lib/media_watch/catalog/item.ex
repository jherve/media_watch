defmodule MediaWatch.Catalog.Item do
  # TODO this typespec is incomplete
  @type t() :: %__MODULE__{
          __meta__: Ecto.Schema.Metadata.t(),
          id: integer() | nil,
          module: atom()
        }

  use Ecto.Schema
  import Ecto.Changeset
  alias __MODULE__, as: Item
  alias MediaWatch.Catalog.Show
  alias MediaWatch.Catalog.Source
  alias MediaWatch.Catalog.ChannelItem
  alias MediaWatch.Analysis.Description

  schema "watched_items" do
    field :module, Ecto.Enum, values: MediaWatch.Catalog.all()
    has_one :show, Show, foreign_key: :id
    has_many :sources, Source, foreign_key: :item_id
    has_many :channel_items, ChannelItem
    has_many :channels, through: [:channel_items, :channel]
    has_one :description, Description
  end

  @doc false
  def changeset(item \\ %Item{}, attrs) do
    item
    |> cast(attrs, [:id, :module])
    |> cast_assoc(:show)
    |> validate_required_inclusion([:show])
    |> cast_assoc(:sources, required: true)
    |> unique_constraint(:module)
  end

  def validate_required_inclusion(changeset, fields) do
    if Enum.any?(fields, &present?(changeset, &1)) do
      changeset
    else
      # Add the error to the first field only since Ecto requires a field name for each error.
      add_error(changeset, hd(fields), "One of these fields must be present: #{inspect(fields)}")
    end
  end

  def present?(changeset, field) do
    case changeset |> fetch_field(field) do
      {_, val} when not is_nil(val) -> true
      {_, nil} -> false
    end
  end

  defmacro __using__(opts) do
    quote bind_quoted: [opts: opts] do
      use MediaWatch.Catalog.Catalogable, repo: MediaWatch.Repo
      use MediaWatch.Snapshots.Snapshotable
      use MediaWatch.Parsing.Parsable
      use MediaWatch.Parsing.Sliceable
      use MediaWatch.Analysis.Describable
      use MediaWatch.Analysis.Recurrent
      import Ecto.Query

      @show opts[:show]
      @item_args (cond do
                    not is_nil(@show) -> %{show: @show}
                    true -> raise("At least one of [`show`] should be set")
                  end)
      @sources opts[:sources] || raise("`sources` should be set")
      @channel_names opts[:channel_names] || raise("`channel_names` should be set")

      @impl true
      def query(), do: from(i in Item, as: :item, where: i.module == ^__MODULE__)

      @impl true
      def insert() do
        repo = get_repo()
        channels = get_channels(repo)

        %{module: __MODULE__, sources: @sources}
        |> Map.merge(@item_args)
        |> Item.changeset()
        |> change(channel_items: channels |> Enum.map(&%ChannelItem{channel: &1}))
        |> MediaWatch.Repo.insert_and_retry(repo)
      end

      @impl true
      def get() do
        import Ecto.Query
        repo = get_repo()

        from(i in query(), preload: [:channels, :show, sources: [:rss_feed]])
        |> repo.one()
      end

      @impl true
      defdelegate make_snapshot(source), to: MediaWatch.Catalog.Source

      @impl true
      defdelegate parse(source), to: MediaWatch.Snapshots.Snapshot

      @impl true
      defdelegate slice(parsed), to: MediaWatch.Parsing.ParsedSnapshot

      @impl true
      defdelegate create_description(slice), to: MediaWatch.Parsing.Slice

      @impl true
      defdelegate create_occurrence(slice), to: MediaWatch.Parsing.Slice
      @impl true
      defdelegate update_occurrence(occ, slice), to: MediaWatch.Parsing.Slice

      @impl true
      def get_occurrences_within_time_slot(datetime) do
        repo = get_repo()
        query = from(i in query(), select: i.id)

        with {slot_start, slot_end} <- get_time_slot(datetime) do
          from(o in MediaWatch.Analysis.ShowOccurrence,
            where:
              o.show_id in subquery(query) and o.date_start >= ^slot_start and
                o.date_start < ^slot_end
          )
          |> repo.all
        end
      end

      defoverridable make_snapshot: 1,
                     parse: 1,
                     slice: 1,
                     create_description: 1,
                     create_occurrence: 1,
                     update_occurrence: 2

      defp get_channels(repo) do
        import Ecto.Query
        alias MediaWatch.Catalog.Channel

        from(c in Channel, where: c.name in ^@channel_names)
        |> repo.all()
      end
    end
  end
end
