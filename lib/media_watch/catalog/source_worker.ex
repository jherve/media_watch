defmodule MediaWatch.Catalog.SourceWorker do
  use GenServer
  require Logger
  alias MediaWatch.{Catalog, Snapshots, Parsing, Analysis, PubSub}
  alias MediaWatch.Snapshots.Snapshot
  alias MediaWatch.Parsing.{ParsedSnapshot, Slice}
  @max_snapshot_retries 3

  def start_link(source_id) do
    GenServer.start_link(__MODULE__, source_id, name: to_name(source_id))
  end

  def do_snapshots(source_id), do: GenServer.cast(to_name(source_id), :do_snapshots)

  @impl true
  def init(id) do
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
    # TODO: Publish slices on success
    attempt_catchup(state, :snapshots)
    attempt_catchup(state, :parsed_snapshots)

    {:noreply, state}
  end

  @impl true
  def handle_cast(:do_snapshots, state = %{source: source}) do
    with {:ok, snap} <- do_snapshot(state.module, source),
         state <- update_in(state.snapshots, &append(&1, snap)),
         {:ok, parsed, state} <- do_parsing(snap, state),
         {:ok, new_slices, state} <- do_slicing(parsed, state),
         {:ok, entities, state} when is_list(entities) <-
           new_slices |> do_entity_recognition(state) do
      PubSub.broadcast("snapshots:#{state.id}", snap)
      PubSub.broadcast("parsing:#{state.id}", parsed)
      new_slices |> Enum.each(&PubSub.broadcast("slicing:#{state.id}", &1))
      {:noreply, state}
    else
      {:error, _} ->
        {:noreply, state}

      {:error, _, state} ->
        {:noreply, state}
    end
  end

  defp do_parsing(snap = %Snapshot{}, state) do
    case snap |> Parsing.parse_and_insert() do
      {:ok, parsed} -> {:ok, parsed, update_in(state.parsed_snapshots, &append(&1, parsed))}
      {:error, e} -> {:error, e, state}
    end
  end

  defp do_slicing(snap = %ParsedSnapshot{}, state = %{module: module}) do
    new_slices =
      case Parsing.get(snap.id) |> Parsing.slice_and_insert(module) do
        {:ok, ok, _} ->
          ok

        {:error, ok, _, errors} ->
          Logger.error("#{errors |> Enum.count()} errors on slices insertion")
          ok
      end

    {:ok, new_slices, update_in(state.slices, &append(&1, new_slices))}
  end

  defp do_entity_recognition(slices_list, state) when is_list(slices_list),
    do: {:ok, slices_list |> Enum.flat_map(&do_entity_recognition(&1, state)), state}

  defp do_entity_recognition(slice = %Slice{}, %{module: module}) do
    slice
    |> Analysis.insert_entities_from(module)
    |> Enum.filter(&match?({:ok, _}, &1))
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

  defp catchup(snap = %Snapshot{}, state), do: do_parsing(snap, state)

  defp catchup(parsed = %ParsedSnapshot{}, state), do: do_slicing(parsed, state)

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
    case Snapshots.make_snapshot_and_insert(source) do
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
