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

  defmacro __using__(_opts) do
    quote do
      use MediaWatch.Catalog.Catalogable, repo: MediaWatch.Repo
      use MediaWatch.Catalog.Source
      use MediaWatch.Snapshots.Snapshot
      use MediaWatch.Parsing.ParsedSnapshot
      use MediaWatch.Parsing.Slice
      use MediaWatch.Analysis.Recognisable
      import Ecto.Query

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

      @impl true
      def query(), do: from(i in Item, as: :item, where: i.module == ^__MODULE__)

      @impl true
      def insert() do
        repo = get_repo()
        channels = @channels |> Enum.map(& &1.get())

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
      def get_airing_schedule(), do: @airing_schedule |> Crontab.CronExpression.Parser.parse!()

      @impl MediaWatch.Analysis.Recognisable
      defdelegate get_guests_cs(occ, list_of_attrs), to: MediaWatch.Analysis.Invitation
      @impl MediaWatch.Analysis.Recognisable
      defdelegate insert_guests(cs_list, repo), to: MediaWatch.Analysis.Invitation
    end
  end
end
