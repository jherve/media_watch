defmodule MediaWatch.Catalog.ItemWorker do
  use GenServer
  require Logger
  alias MediaWatch.{PubSub, Parsing, Snapshots, Analysis}
  alias MediaWatch.Catalog.{Item, Source}
  alias MediaWatch.Snapshots.Snapshot
  alias MediaWatch.Parsing.{ParsedSnapshot, Slice}
  alias MediaWatch.Analysis.{ShowOccurrence, Description, Invitation}
  @max_snapshot_retries 3

  def start_link(module) when is_atom(module) do
    GenServer.start_link(__MODULE__, module, name: module)
  end

  def do_snapshots(module), do: GenServer.cast(module, :do_snapshots)

  @impl true
  def init(module) when is_atom(module) do
    case module.get() do
      nil ->
        case module.insert() do
          {:ok, item} ->
            item |> init(module)

          {:error, _} ->
            Logger.warning("Could not start #{module}")
            {:ok, nil}
        end

      item ->
        item |> init(module)
    end
  end

  def init(item = %Item{id: id}, module) do
    PubSub.subscribe("snapshots:#{id}")
    PubSub.subscribe("parsing:#{id}")
    PubSub.subscribe("slicing:#{id}")
    PubSub.subscribe("occurrence_formatting:#{id}")
    sources = item.sources
    source_ids = sources |> Enum.map(& &1.id)

    {:ok,
     %{
       id: id,
       module: module,
       item: item,
       sources: sources,
       description: id |> Analysis.get_description(),
       occurrences: item.show.id |> Analysis.get_occurrences(),
       snapshots: source_ids |> Snapshots.get_snapshots() |> default_to_source_id_map(source_ids),
       parsed_snapshots:
         source_ids |> Parsing.get_parsed() |> default_to_source_id_map(source_ids),
       slices: source_ids |> Parsing.get_slices() |> default_to_source_id_map(source_ids)
     }, {:continue, :do_catchup}}
  end

  @impl true
  def handle_continue(:do_catchup, state) do
    {:noreply, state |> attempt_catchup(state.module)}
  end

  @impl true
  def handle_cast(:do_snapshots, state = %{sources: sources}) do
    snap_results =
      sources
      |> Map.new(&{&1.id, do_snapshot(state.module, &1)})
      |> keep_ok_results()
      |> tap(&publish_result(&1, state.id))

    {:noreply, state |> update_state(snap_results)}
  end

  @impl true
  def handle_info(snap = %Snapshot{}, state = %{module: module}) do
    repo = module.get_repo()

    res =
      snap
      |> Snapshot.parse_and_insert(repo, module)
      |> tap(&publish_result(&1, state.id))

    {:noreply, state |> update_state(res, snap.source_id)}
  end

  def handle_info(snap = %ParsedSnapshot{}, state = %{module: module}) do
    ok_res =
      case Parsing.get(snap.id) |> ParsedSnapshot.slice_and_insert(module.get_repo(), module) do
        {:ok, ok, _} ->
          ok

        {:error, ok, _, errors} ->
          Logger.error("#{errors |> Enum.count()} errors on slices insertion")
          ok
      end

    ok_res |> publish_result(state.id)
    ok_res = ok_res |> Map.new(&{&1.source.id, &1})

    {:noreply, state |> update_state(ok_res)}
  end

  def handle_info(slice = %Slice{type: :rss_channel_description}, state = %{module: module}) do
    res =
      slice
      |> Description.create_description_and_store(module.get_repo(), module)
      |> tap(&publish_result(&1, state.id))

    {:noreply, state |> update_state(res)}
  end

  def handle_info(slice = %Slice{type: :rss_entry}, state = %{module: module}) do
    repo = module.get_repo()

    res =
      case slice |> ShowOccurrence.create_occurrence_and_store(repo, module) do
        ok = {:ok, _} ->
          ok |> tap(&publish_result(&1, state.id))

        {:error, {:unique_airing_time, occ}} ->
          ShowOccurrence.update_occurrence_and_store(occ, slice, repo, module)
          |> tap(&publish_result(&1, state.id))

        e = {:error, reason} ->
          Logger.warning(
            "#{__MODULE__} could not handle slice #{slice.id} because : #{inspect(reason)}"
          )

          e
      end

    {:noreply, state |> update_state(res)}
  end

  def handle_info(occ = %ShowOccurrence{}, state = %{module: module}) do
    res =
      occ
      |> Invitation.insert_guests_from(module.get_repo(), module)
      |> tap(&publish_result(&1, state.id))

    {:noreply, state |> update_state(res)}
  end

  defp attempt_catchup(state, module),
    do:
      state
      |> tap(&attempt_catchup(&1, module, :snapshots))
      |> tap(&attempt_catchup(&1, module, :parsed_snapshots))
      |> tap(&attempt_catchup(&1, module, :slices))

  defp update_state(state, {:ok, res}), do: state |> update_state(res)
  defp update_state(state, {:error, _}), do: state

  defp update_state(state, list) when is_list(list),
    do:
      list
      |> Enum.reduce(state, fn obj, state -> state |> update_state(obj) end)

  defp update_state(state, desc = %Description{}), do: %{state | description: desc}

  defp update_state(state, occ = %ShowOccurrence{}),
    do: update_in(state.occurrences, &append(&1, occ))

  defp update_state(state, %Invitation{}), do: state

  defp update_state(state, map) when is_map(map) and not is_struct(map),
    do:
      map
      |> Enum.reduce(state, fn {source_id, snap}, state ->
        state |> update_state(snap, source_id)
      end)

  defp update_state(state, {:ok, res}, source_id), do: state |> update_state(res, source_id)
  defp update_state(state, {:error, _}, _), do: state

  defp update_state(state, snap = %Snapshot{}, source_id),
    do: update_in(state.snapshots[source_id], &append(&1, snap))

  defp update_state(state, parsed = %ParsedSnapshot{}, source_id),
    do: update_in(state.parsed_snapshots[source_id], &append(&1, parsed))

  defp update_state(state, slice = %Slice{}, source_id),
    do: update_in(state.slices[source_id], &append(&1, slice))

  defp append(list, elem) when is_list(list), do: list ++ [elem]

  defp publish_result({:ok, res}, item_id), do: publish_result(res, item_id)
  defp publish_result({:error, _}, _), do: :ignore

  defp publish_result(res_list, item_id) when is_list(res_list),
    do: res_list |> Enum.each(&publish_result(&1, item_id))

  defp publish_result(res_map, item_id) when is_map(res_map) and not is_struct(res_map),
    do: res_map |> Map.values() |> Enum.each(&publish_result(&1, item_id))

  defp publish_result(obj = %struct{}, item_id),
    do: PubSub.broadcast("#{to_chan_root(struct)}:#{item_id}", obj)

  defp to_chan_root(Snapshot), do: "snapshots"
  defp to_chan_root(ParsedSnapshot), do: "parsing"
  defp to_chan_root(Slice), do: "slicing"
  defp to_chan_root(Description), do: "description"
  defp to_chan_root(ShowOccurrence), do: "occurrence_formatting"
  defp to_chan_root(Invitation), do: "invitation"

  defp do_snapshot(module, source, nb_retries \\ 0)

  defp do_snapshot(module, _, nb_retries) when nb_retries > @max_snapshot_retries do
    Logger.warning("Could not snapshot #{module} despite #{nb_retries} retries")
    {:error, reason: :max_retries}
  end

  defp do_snapshot(module, source, nb_retries) do
    case Source.make_snapshot_and_insert(source, module.get_repo(), module) do
      ok = {:ok, _} ->
        ok

      {:error, %{reason: :timeout}} ->
        Logger.warning("Retrying snapshot for #{module}")
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

  defp attempt_catchup(state, module, :snapshots) do
    snap_ids = state.parsed_snapshots |> flatten_map(& &1.snapshot_id)

    state.snapshots
    |> flatten_map()
    |> Enum.reject(&(&1.id in snap_ids))
    |> tap(&do_catchup(&1, state, module))
  end

  defp attempt_catchup(state, module, :parsed_snapshots) do
    slices_ids = state.slices |> flatten_map(& &1.parsed_snapshot_id)

    state.parsed_snapshots
    |> flatten_map()
    |> Enum.reject(&(&1.id in slices_ids))
    |> tap(&do_catchup(&1, state, module))
  end

  defp attempt_catchup(state, module, :slices) do
    description = state.description || %{slices_used: [], slices_discarded: []}

    slices_seen =
      description.slices_used ++
        description.slices_discarded ++
        (state.occurrences |> Enum.flat_map(&(&1.slices_used ++ &1.slices_discarded)))

    state.slices
    |> flatten_map()
    |> Enum.reject(&(&1.id in slices_seen))
    |> tap(&do_catchup(&1, state, module))
  end

  defp do_catchup(list, state, module) when is_list(list),
    do:
      list
      |> tap(&log_catching_up/1)
      |> Enum.map(&do_catchup(&1, state, module))

  defp do_catchup(obj, state, module) do
    catchup(obj, state, module)
  rescue
    e -> {:error, e}
  end

  defp catchup(snap = %Snapshot{}, state, module), do: module.handle_snapshot(snap, state)

  defp catchup(parsed = %ParsedSnapshot{}, state, module),
    do: module.handle_parsed_snapshot(parsed, state)

  defp catchup(slice = %Slice{}, state, module), do: module.handle_slice(slice, state)

  defp log_catching_up([]), do: nil

  defp log_catching_up(list = [%obj_type{} | _]) when is_list(list),
    do:
      Logger.info("Catching up on #{obj_type} [#{list |> Enum.map(& &1.id) |> Enum.join(", ")}]")

  defp flatten_map(map, fun \\ & &1) when is_map(map) and is_function(fun, 1),
    do: map |> Enum.flat_map(fn {_, list} when is_list(list) -> list |> Enum.map(fun) end)

  defp default_to_source_id_map([], source_ids), do: source_ids |> Map.new(&{&1, []})

  defp default_to_source_id_map(list, _source_ids) when is_list(list),
    do: list |> Enum.group_by(&elem(&1, 0), &elem(&1, 1)) |> Map.new()
end
