defmodule MediaWatch.Catalog.SourceWorker do
  use GenServer
  require Logger
  alias MediaWatch.{Catalog, Snapshots, Parsing, PubSub}
  alias MediaWatch.Catalog.Source
  alias MediaWatch.Snapshots.Snapshot
  alias MediaWatch.Parsing.{ParsedSnapshot, Slice}
  alias MediaWatch.Analysis.EntityRecognized
  @max_snapshot_retries 3

  def start_link(source_id) do
    GenServer.start_link(__MODULE__, source_id, name: to_name(source_id))
  end

  def do_snapshots(source_id), do: GenServer.cast(to_name(source_id), :do_snapshots)

  @impl true
  def init(id) do
    PubSub.subscribe("snapshots:#{id}")
    PubSub.subscribe("parsing:#{id}")
    PubSub.subscribe("slicing:#{id}")

    {:ok,
     %{
       id: id,
       module: Catalog.module_from_source_id(id),
       source: Catalog.get_source(id),
       snapshots: Snapshots.get_snapshots(id),
       parsed_snapshots: Parsing.get_parsed(id),
       slices: Parsing.get_slices(id)
     }, {:continue, :do_catchup}}
  end

  @impl true
  def handle_continue(:do_catchup, state) do
    attempt_catchup(state, :snapshots)
    attempt_catchup(state, :parsed_snapshots)

    {:noreply, state}
  end

  @impl true
  def handle_cast(:do_snapshots, state = %{source: source}) do
    case do_snapshot(state.module, source) do
      {:ok, snap} ->
        PubSub.broadcast("snapshots:#{state.id}", snap)
        {:noreply, update_in(state.snapshots, &append(&1, snap))}

      {:error, _} ->
        {:noreply, state}
    end
  end

  @impl true
  def handle_info(snap = %Snapshot{}, state), do: handle_snapshot(snap, state)
  def handle_info(snap = %ParsedSnapshot{}, state), do: handle_parsed_snapshot(snap, state)
  def handle_info(slice = %Slice{}, state), do: handle_slice(slice, state)

  defp handle_snapshot(snap = %Snapshot{}, state = %{module: module}) do
    repo = module.get_repo()

    case snap |> Snapshot.parse_and_insert(repo, module) do
      {:ok, parsed} ->
        PubSub.broadcast("parsing:#{state.id}", parsed)
        {:noreply, update_in(state.parsed_snapshots, &append(&1, parsed))}

      {:error, _} ->
        {:noreply, state}
    end
  end

  defp handle_parsed_snapshot(snap = %ParsedSnapshot{}, state = %{module: module}) do
    new_slices =
      case Parsing.get(snap.id) |> ParsedSnapshot.slice_and_insert(module.get_repo(), module) do
        {:ok, ok, _} ->
          ok

        {:error, ok, _, errors} ->
          Logger.error("#{errors |> Enum.count()} errors on slices insertion")
          ok
      end

    new_slices |> Enum.map(&PubSub.broadcast("slicing:#{state.id}", &1))

    {:noreply, update_in(state.slices, &append(&1, new_slices))}
  end

  defp handle_slice(slice = %Slice{}, state = %{module: module}) do
    ok_res =
      slice
      |> EntityRecognized.insert_entities_from(module.get_repo(), module)
      |> Enum.filter(&match?({:ok, _}, &1))

    ok_res |> Enum.each(&PubSub.broadcast("entity_recognized:#{state.id}", &1))
    {:noreply, state}
  end

  defp attempt_catchup(state, :snapshots) do
    snap_ids = state.parsed_snapshots |> Enum.map(& &1.snapshot_id)

    state.snapshots
    |> Enum.reject(&(&1.id in snap_ids))
    |> tap(&do_catchup(&1, state))
  end

  defp attempt_catchup(state, :parsed_snapshots) do
    slices_ids = state.slices |> Enum.map(& &1.parsed_snapshot_id)

    state.parsed_snapshots
    |> Enum.reject(&(&1.id in slices_ids))
    |> tap(&do_catchup(&1, state))
  end

  defp do_catchup(list, state) when is_list(list),
    do:
      list
      |> tap(&log_catching_up/1)
      |> Enum.map(&do_catchup(&1, state))

  defp do_catchup(obj, state) do
    catchup(obj, state)
  rescue
    e -> {:error, e}
  end

  defp catchup(snap = %Snapshot{}, state), do: handle_snapshot(snap, state)

  defp catchup(parsed = %ParsedSnapshot{}, state), do: handle_parsed_snapshot(parsed, state)

  defp log_catching_up([]), do: nil

  defp log_catching_up(list = [%obj_type{} | _]) when is_list(list),
    do:
      Logger.info("Catching up on #{obj_type} [#{list |> Enum.map(& &1.id) |> Enum.join(", ")}]")

  defp append(list, list2) when is_list(list) and is_list(list2), do: list ++ list2
  defp append(list, elem) when is_list(list), do: list ++ [elem]

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
        do_snapshot(module, source, nb_retries + 1)

      error = {:error, _} ->
        error
    end
  end

  defp to_name(source_id), do: :"#{__MODULE__}.#{source_id}"
end
