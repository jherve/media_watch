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
      @behaviour MediaWatch.Catalog.Catalogable
      @behaviour MediaWatch.Parsing.Parsable
      @behaviour MediaWatch.Parsing.Sliceable
      @behaviour MediaWatch.Analysis.Analyzable
      @behaviour MediaWatch.Analysis.Describable
      @behaviour MediaWatch.Analysis.Recognisable
      @behaviour MediaWatch.Analysis.Hosted
      use MediaWatch.Analysis.Recurrent
      import Ecto.Query
      alias MediaWatch.Repo
      alias MediaWatch.Catalog.Source
      alias MediaWatch.Snapshots.Snapshot
      alias MediaWatch.Parsing.{ParsedSnapshot, Slice}

      alias MediaWatch.Analysis.{
        SliceUsage,
        ShowOccurrence,
        ShowOccurrence.Invitation,
        EntityRecognized
      }

      @config Application.compile_env(:media_watch, MediaWatch.Catalog)[:items][__MODULE__] ||
                raise("Config for #{__MODULE__} should be set")

      @show @config[:show]
      @item_args (cond do
                    not is_nil(@show) -> %{show: @show}
                    true -> raise("At least one of [`show`] should be set")
                  end)
      @airing_schedule @show[:airing_schedule] || raise("`show.airing_schedule` should be set")
      @hosts @show[:host_names]
      @alternate_hosts @show[:alternate_hosts]
      @columnists @show[:columnists]
      @sources @config[:sources] || raise("`sources` should be set")
      @channels @config[:channels] || raise("`channels` should be set")

      @impl MediaWatch.Catalog.Catalogable
      def query(), do: from(i in Item, as: :item, where: i.module == ^__MODULE__)

      @impl MediaWatch.Catalog.Catalogable
      def insert() do
        channels = @channels |> Enum.map(& &1.get())

        %{module: __MODULE__, sources: @sources}
        |> Map.merge(@item_args)
        |> Item.changeset()
        |> change(channel_items: channels |> Enum.map(&%ChannelItem{channel: &1}))
        |> Repo.insert_and_retry()
      end

      @impl MediaWatch.Catalog.Catalogable
      def get() do
        from(i in query(), preload: [:channels, :show, sources: [:rss_feed, :web_index_page]])
        |> Repo.one()
      end

      @impl MediaWatch.Parsing.Parsable
      defdelegate parse_snapshot(snap), to: Snapshot

      @impl MediaWatch.Parsing.Parsable
      defdelegate prune_snapshot(data, snap), to: Snapshot

      @impl MediaWatch.Parsing.Sliceable
      defdelegate into_list_of_slice_attrs(parsed), to: ParsedSnapshot

      @impl MediaWatch.Parsing.Sliceable
      defdelegate into_slice_cs(attrs, parsed), to: ParsedSnapshot

      @impl MediaWatch.Analysis.Analyzable
      defdelegate classify(slice), to: SliceUsage

      @impl MediaWatch.Analysis.Describable
      defdelegate get_description_attrs(item_id, slice), to: Description

      @impl MediaWatch.Analysis.Recurrent
      def get_airing_schedule(), do: @airing_schedule |> Crontab.CronExpression.Parser.parse!()

      @impl MediaWatch.Analysis.Recognisable
      def get_guests_attrs(occ), do: Invitation.get_guests_attrs(occ, __MODULE__)

      @impl MediaWatch.Analysis.Recognisable
      defdelegate get_entities_cs(occ), to: EntityRecognized

      @impl MediaWatch.Analysis.Hosted
      def get_hosts(), do: @hosts

      if @alternate_hosts do
        @impl MediaWatch.Analysis.Hosted
        def get_alternate_hosts(), do: @alternate_hosts
      end

      if @columnists do
        @impl MediaWatch.Analysis.Hosted
        def get_columnists(), do: @columnists
      end

      defoverridable into_slice_cs: 2,
                     get_description_attrs: 2,
                     classify: 1,
                     prune_snapshot: 2,
                     into_list_of_slice_attrs: 1
    end
  end
end
