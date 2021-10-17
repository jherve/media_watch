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

  schema "catalog_items" do
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

  defmacro __using__(_opts) do
    quote do
      use MediaWatch.Catalog.Catalogable, repo: MediaWatch.Repo
      @behaviour MediaWatch.Snapshots.Snapshotable
      @behaviour MediaWatch.Parsing.Parsable
      @behaviour MediaWatch.Parsing.Sliceable
      @behaviour MediaWatch.Analysis.Describable
      @behaviour MediaWatch.Analysis.Recognisable
      use MediaWatch.Analysis.Recurrent
      import Ecto.Query
      alias MediaWatch.Catalog.Source
      alias MediaWatch.Snapshots.Snapshot
      alias MediaWatch.Parsing.{ParsedSnapshot, Slice}
      alias MediaWatch.Analysis.{ShowOccurrence, Invitation, EntityRecognized}

      @config Application.compile_env(:media_watch, MediaWatch.Catalog)[:items][__MODULE__] ||
                raise("Config for #{__MODULE__} should be set")

      @show @config[:show]
      @item_args (cond do
                    not is_nil(@show) -> %{show: @show}
                    true -> raise("At least one of [`show`] should be set")
                  end)
      @airing_schedule @show[:airing_schedule] || raise("`show.airing_schedule` should be set")
      @sources @config[:sources] || raise("`sources` should be set")
      @channels @config[:channels] || raise("`channels` should be set")

      @impl MediaWatch.Catalog.Catalogable
      def query(), do: from(i in Item, as: :item, where: i.module == ^__MODULE__)

      @impl MediaWatch.Catalog.Catalogable
      def insert() do
        repo = get_repo()
        channels = @channels |> Enum.map(& &1.get())

        %{module: __MODULE__, sources: @sources}
        |> Map.merge(@item_args)
        |> Item.changeset()
        |> change(channel_items: channels |> Enum.map(&%ChannelItem{channel: &1}))
        |> MediaWatch.Repo.insert_and_retry(repo)
      end

      @impl MediaWatch.Catalog.Catalogable
      def get() do
        repo = get_repo()

        from(i in query(), preload: [:channels, :show, sources: [:rss_feed]])
        |> repo.one()
      end

      @impl MediaWatch.Snapshots.Snapshotable
      defdelegate make_snapshot(source), to: Source

      @impl MediaWatch.Parsing.Parsable
      defdelegate parse(source), to: Snapshot

      @impl MediaWatch.Parsing.Sliceable
      def slice(parsed), do: ParsedSnapshot.slice(parsed, __MODULE__)

      @impl MediaWatch.Parsing.Sliceable
      defdelegate into_slice_cs(attrs, parsed), to: ParsedSnapshot

      @impl MediaWatch.Analysis.Describable
      defdelegate create_description(slice), to: Description

      @impl MediaWatch.Analysis.Recurrent
      def create_occurrence(slice), do: ShowOccurrence.create_occurrence(slice, __MODULE__)

      @impl MediaWatch.Analysis.Recurrent
      defdelegate update_occurrence(occ, used, discarded, new), to: ShowOccurrence

      @impl MediaWatch.Analysis.Recurrent
      def get_occurrence_at(datetime), do: ShowOccurrence.get_occurrence_at(datetime, __MODULE__)

      @impl MediaWatch.Analysis.Recurrent
      def get_slices_from_occurrence(occ),
        do: ShowOccurrence.get_slices_from_occurrence(occ, get_repo())

      @impl MediaWatch.Analysis.Recurrent
      def get_airing_schedule(), do: @airing_schedule |> Crontab.CronExpression.Parser.parse!()

      @impl MediaWatch.Analysis.Recognisable
      defdelegate get_entities_cs(occ), to: EntityRecognized

      defoverridable into_slice_cs: 2,
                     create_description: 1,
                     create_occurrence: 1,
                     update_occurrence: 4
    end
  end
end
