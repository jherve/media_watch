defmodule MediaWatch.Catalog.ItemWorker do
  use GenServer
  require Logger
  alias MediaWatch.{Repo, PubSub, Parsing, Snapshots, Analysis}
  alias MediaWatch.Catalog.Item
  alias MediaWatch.Snapshots.Snapshot
  alias MediaWatch.Parsing.{ParsedSnapshot, Slice}
  alias MediaWatch.Analysis.{Description, ShowOccurrence}
  @max_snapshot_retries 3

  def start_link(module) when is_atom(module) do
    GenServer.start_link(__MODULE__, module, name: module)
  end

  def do_snapshots(module) when is_atom(module), do: GenServer.cast(module, :do_snapshots)

  @impl true
  def init(module) when is_atom(module) do
    case module.get(Repo) do
      nil ->
        case module.insert(Repo) do
          {:ok, item} ->
            item |> init()

          {:error, _} ->
            Logger.warning("Could not start #{module}")
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
     %{id: id, item: item, module: item.module, sources: sources}
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
      |> Map.new(&{&1.id, make_snapshot(&1, state.module)})
      |> keep_ok_results()
      |> tap(&publish_result(&1, state.id))

    {:noreply, state |> update_state(snap_results)}
  end

  @impl true
  def handle_info(snap = %Snapshot{}, state) do
    res = snap |> state.module.parse_and_insert(Repo) |> tap(&publish_result(&1, state.id))
    {:noreply, state |> update_state(res, snap.source_id)}
  end

  def handle_info(snap = %ParsedSnapshot{}, state) do
    ok_res =
      case Parsing.get(snap.id) |> state.module.slice_and_insert(Repo) do
        {:ok, ok, _} ->
          ok

        {:error, ok, _, errors} ->
          Logger.error("#{errors |> Enum.count()} errors on slices insertion")
          ok
      end

    ok_res |> publish_result(state.id)

    {:noreply, state |> update_state(ok_res |> Map.new(&{&1.source.id, &1}))}
  end

  def handle_info(slice = %Slice{type: :rss_channel_description}, state) do
    res = slice |> state.module.describe_and_insert(Repo) |> tap(&publish_result(&1, state.id))
    {:noreply, state |> update_state(res)}
  end

  def handle_info(slice = %Slice{type: :rss_entry}, state) do
    res =
      slice
      |> state.module.format_occurrence_and_insert(Repo)
      |> tap(&publish_result(&1, state.id))

    {:noreply, state |> update_state(res)}
  end

  defp make_snapshot(source, module, nb_retries \\ 0)

  defp make_snapshot(_, module, nb_retries) when nb_retries > @max_snapshot_retries do
    Logger.warning("Could not snapshot #{module} despite #{nb_retries} retries")
    {:error, reason: :max_retries}
  end

  defp make_snapshot(source, module, nb_retries) do
    case module.make_snapshot_and_insert(source, MediaWatch.Repo) do
      ok = {:ok, _} ->
        ok

      {:error, %{reason: :timeout}} ->
        Logger.warning("Retrying snapshot for #{module}")
        make_snapshot(source, module, nb_retries + 1)

      error = {:error, _} ->
        error
    end
  end

  defp keep_ok_results(res_map) when is_map(res_map),
    do:
      res_map
      |> Enum.filter(&match?({_, {:ok, _}}, &1))
      |> Map.new(fn {k, {:ok, res}} -> {k, res} end)

  defp init_state(state, key = :description),
    do:
      state
      |> Map.put(key, state.id |> Analysis.get_description())

  defp init_state(state, key = :occurrences),
    do:
      state
      |> Map.put(key, state.item.show.id |> Analysis.get_occurrences())

  defp init_state(state, key), do: init_state(state, key, state.sources |> Enum.map(& &1.id))

  defp init_state(state, key = :snapshots, source_ids),
    do:
      state
      |> Map.put(
        key,
        source_ids |> Snapshots.get_snapshots() |> default_to_source_id_map(source_ids)
      )

  defp init_state(state, key = :parsed_snapshots, source_ids),
    do:
      state
      |> Map.put(
        key,
        source_ids |> Parsing.get_parsed() |> default_to_source_id_map(source_ids)
      )

  defp init_state(state, key = :slices, source_ids),
    do:
      state
      |> Map.put(
        key,
        source_ids |> Parsing.get_slices() |> default_to_source_id_map(source_ids)
      )

  defp update_state(state, {:ok, res}), do: state |> update_state(res)
  defp update_state(state, {:error, _}), do: state

  defp update_state(state, desc = %Description{}), do: %{state | description: desc}

  defp update_state(state, occ = %ShowOccurrence{}),
    do: update_in(state.occurrences, &append(&1, occ))

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

  defp publish_result(snap = %Snapshot{}, item_id),
    do: PubSub.broadcast("snapshots:#{item_id}", snap)

  defp publish_result(parsed = %ParsedSnapshot{}, item_id),
    do: PubSub.broadcast("parsing:#{item_id}", parsed)

  defp publish_result(slice = %Slice{}, item_id),
    do: PubSub.broadcast("slicing:#{item_id}", slice)

  defp publish_result(desc = %Description{}, item_id),
    do: PubSub.broadcast("description:#{item_id}", {:new_description, desc})

  defp publish_result(occ = %ShowOccurrence{}, item_id),
    do: PubSub.broadcast("occurrence_formatting:#{item_id}", {:new_occurrence, occ})

  defp default_to_source_id_map([], source_ids), do: source_ids |> Map.new(&{&1, []})
  defp default_to_source_id_map(list, _source_ids) when is_list(list), do: list |> Map.new()
end
