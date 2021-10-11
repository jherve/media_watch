defmodule MediaWatch.Catalog.ItemWorker do
  @callback init_state(map(), atom()) :: map()
  @callback update_state(map(), atom()) :: map()
  @callback update_state(map(), atom(), any()) :: map()
  @callback publish_result(any(), any()) :: :ok
  @callback handle_snapshot(MediaWatch.Snapshots.Snapshot.t(), map()) ::
              {MediaWatch.Parsing.ParsedSnapshot.t(), map()}
  @callback handle_parsed_snapshot(MediaWatch.Parsing.ParsedSnapshot.t(), map()) ::
              {[MediaWatch.Parsing.Slice.t()], map()}
  @callback handle_slice(MediaWatch.Parsing.Slice.t(), map()) ::
              {MediaWatch.Analysis.Description.t() | MediaWatch.Analysis.ShowOccurrence.t(),
               map()}

  defmacro __using__(opts) do
    quote bind_quoted: [opts: opts] do
      use GenServer
      use MediaWatch.Catalog.Item, opts
      @behaviour MediaWatch.Catalog.ItemWorker
      @name __MODULE__

      require Logger
      alias MediaWatch.{PubSub, Parsing, Snapshots, Analysis}
      alias MediaWatch.Catalog.Item
      alias MediaWatch.Snapshots.Snapshot
      alias MediaWatch.Parsing.{ParsedSnapshot, Slice}
      @max_snapshot_retries 3

      def start_link([]) do
        GenServer.start_link(__MODULE__, [], name: @name)
      end

      def do_snapshots(), do: GenServer.cast(@name, :do_snapshots)

      @impl true
      def init([]) do
        case get() do
          nil ->
            case insert() do
              {:ok, item} ->
                item |> init()

              {:error, _} ->
                Logger.warning("Could not start #{@name}")
                {:ok, nil}
            end

          item ->
            item |> init()
        end
      end

      def init(item = %Item{id: id}) do
        PubSub.subscribe("snapshots:#{id}")
        PubSub.subscribe("parsing:#{id}")
        PubSub.subscribe("slicing:#{id}")
        sources = item.sources

        {:ok,
         %{id: id, item: item, sources: sources}
         |> init_state(:snapshots)
         |> init_state(:parsed_snapshots)
         |> init_state(:slices)
         |> init_state(:description)
         |> init_state(:occurrences)}
      end

      @impl true
      def handle_cast(:do_snapshots, state = %{sources: sources}) do
        snap_results =
          sources
          |> Map.new(&{&1.id, do_snapshot(&1)})
          |> keep_ok_results()
          |> tap(&publish_result(&1, state.id))

        {:noreply, state |> update_state(snap_results)}
      end

      @impl true
      def handle_info(snap = %Snapshot{}, state) do
        {res, state} = handle_snapshot(snap, state)
        {:noreply, state}
      end

      def handle_info(snap = %ParsedSnapshot{}, state) do
        {res, state} = handle_parsed_snapshot(snap, state)
        {:noreply, state}
      end

      def handle_info(slice = %Slice{}, state) do
        {res, state} = handle_slice(slice, state)
        {:noreply, state}
      end

      @impl true
      defdelegate init_state(state, key), to: MediaWatch.Catalog.ItemWorker
      @impl true
      defdelegate update_state(state, key), to: MediaWatch.Catalog.ItemWorker
      @impl true
      defdelegate update_state(state, key, source_id), to: MediaWatch.Catalog.ItemWorker
      @impl true
      defdelegate publish_result(res, id), to: MediaWatch.Catalog.ItemWorker

      @impl true
      def handle_snapshot(snap, state) do
        res = snap |> parse_and_insert(get_repo()) |> tap(&publish_result(&1, state.id))
        {res, state |> update_state(res, snap.source_id)}
      end

      @impl true
      def handle_parsed_snapshot(snap = %ParsedSnapshot{}, state) do
        ok_res =
          case Parsing.get(snap.id) |> slice_and_insert(get_repo()) do
            {:ok, ok, _} ->
              ok

            {:error, ok, _, errors} ->
              Logger.error("#{errors |> Enum.count()} errors on slices insertion")
              ok
          end

        ok_res |> publish_result(state.id)
        ok_res = ok_res |> Map.new(&{&1.source.id, &1})

        {ok_res, state |> update_state(ok_res)}
      end

      @impl true
      def handle_slice(slice = %Slice{type: :rss_channel_description}, state) do
        res =
          slice |> create_description_and_store(get_repo()) |> tap(&publish_result(&1, state.id))

        {res, state |> update_state(res)}
      end

      def handle_slice(slice = %Slice{type: :rss_entry}, state) do
        res =
          case slice |> create_occurrence_and_store(get_repo()) do
            ok = {:ok, _} ->
              ok |> tap(&publish_result(&1, state.id))

            {:error, {:unique_airing_time, occ}} ->
              update_occurrence_and_store(occ, slice, get_repo())
              |> tap(&publish_result(&1, state.id))

            e = {:error, reason} ->
              Logger.warning(
                "#{__MODULE__} could not handle slice #{slice.id} because : #{inspect(reason)}"
              )

              e
          end

        {res, state |> update_state(res)}
      end

      defoverridable handle_snapshot: 2, handle_parsed_snapshot: 2, handle_slice: 2

      defp do_snapshot(source, nb_retries \\ 0)

      defp do_snapshot(_, nb_retries) when nb_retries > @max_snapshot_retries do
        Logger.warning("Could not snapshot #{@name} despite #{nb_retries} retries")
        {:error, reason: :max_retries}
      end

      defp do_snapshot(source, nb_retries) do
        case make_snapshot_and_insert(source, get_repo()) do
          ok = {:ok, _} ->
            ok

          {:error, %{reason: :timeout}} ->
            Logger.warning("Retrying snapshot for #{@name}")
            do_snapshot(source, nb_retries + 1)

          error = {:error, _} ->
            error
        end
      end

      defp keep_ok_results(res_map) when is_map(res_map),
        do:
          res_map
          |> Enum.filter(&match?({_, {:ok, _}}, &1))
          |> Map.new(fn {k, {:ok, res}} -> {k, res} end)
    end
  end

  alias MediaWatch.{PubSub, Parsing, Snapshots, Analysis}
  alias MediaWatch.Snapshots.Snapshot
  alias MediaWatch.Parsing.{ParsedSnapshot, Slice}
  alias MediaWatch.Analysis.{Description, ShowOccurrence}

  def init_state(state, key = :description),
    do:
      state
      |> Map.put(key, state.id |> Analysis.get_description())

  def init_state(state, key = :occurrences),
    do:
      state
      |> Map.put(key, state.item.show.id |> Analysis.get_occurrences())

  def init_state(state, key), do: init_state(state, key, state.sources |> Enum.map(& &1.id))

  def init_state(state, key = :snapshots, source_ids),
    do:
      state
      |> Map.put(
        key,
        source_ids |> Snapshots.get_snapshots() |> default_to_source_id_map(source_ids)
      )

  def init_state(state, key = :parsed_snapshots, source_ids),
    do:
      state
      |> Map.put(
        key,
        source_ids |> Parsing.get_parsed() |> default_to_source_id_map(source_ids)
      )

  def init_state(state, key = :slices, source_ids),
    do:
      state
      |> Map.put(
        key,
        source_ids |> Parsing.get_slices() |> default_to_source_id_map(source_ids)
      )

  def update_state(state, {:ok, res}), do: state |> update_state(res)
  def update_state(state, {:error, _}), do: state

  def update_state(state, desc = %Description{}), do: %{state | description: desc}

  def update_state(state, occ = %ShowOccurrence{}),
    do: update_in(state.occurrences, &append(&1, occ))

  def update_state(state, map) when is_map(map) and not is_struct(map),
    do:
      map
      |> Enum.reduce(state, fn {source_id, snap}, state ->
        state |> update_state(snap, source_id)
      end)

  def update_state(state, {:ok, res}, source_id), do: state |> update_state(res, source_id)
  def update_state(state, {:error, _}, _), do: state

  def update_state(state, snap = %Snapshot{}, source_id),
    do: update_in(state.snapshots[source_id], &append(&1, snap))

  def update_state(state, parsed = %ParsedSnapshot{}, source_id),
    do: update_in(state.parsed_snapshots[source_id], &append(&1, parsed))

  def update_state(state, slice = %Slice{}, source_id),
    do: update_in(state.slices[source_id], &append(&1, slice))

  def append(list, elem) when is_list(list), do: list ++ [elem]

  def publish_result({:ok, res}, item_id), do: publish_result(res, item_id)
  def publish_result({:error, _}, _), do: :ignore

  def publish_result(res_list, item_id) when is_list(res_list),
    do: res_list |> Enum.each(&publish_result(&1, item_id))

  def publish_result(res_map, item_id) when is_map(res_map) and not is_struct(res_map),
    do: res_map |> Map.values() |> Enum.each(&publish_result(&1, item_id))

  def publish_result(snap = %Snapshot{}, item_id),
    do: PubSub.broadcast("snapshots:#{item_id}", snap)

  def publish_result(parsed = %ParsedSnapshot{}, item_id),
    do: PubSub.broadcast("parsing:#{item_id}", parsed)

  def publish_result(slice = %Slice{}, item_id),
    do: PubSub.broadcast("slicing:#{item_id}", slice)

  def publish_result(desc = %Description{}, item_id),
    do: PubSub.broadcast("description:#{item_id}", desc)

  def publish_result(occ = %ShowOccurrence{}, item_id),
    do: PubSub.broadcast("occurrence_formatting:#{item_id}", occ)

  defp default_to_source_id_map([], source_ids), do: source_ids |> Map.new(&{&1, []})

  defp default_to_source_id_map(list, _source_ids) when is_list(list),
    do: list |> Enum.group_by(&elem(&1, 0), &elem(&1, 1)) |> Map.new()
end
