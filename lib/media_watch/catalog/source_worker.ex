defmodule MediaWatch.Catalog.SourceWorker do
  use GenServer
  require Logger
  alias MediaWatch.{Catalog, PubSub, Utils}
  alias MediaWatch.Snapshots.SnapshotsServer
  alias MediaWatch.Parsing.ParsingServer
  alias MediaWatch.Analysis.EntityRecognitionServer

  def start_link(source_id) do
    # `hibernate_after` option is added in order to try and prevent
    # excessive memory usage. See:
    # https://elixirforum.com/t/extremely-high-memory-usage-in-genservers/4035/25
    GenServer.start_link(__MODULE__, source_id, name: to_name(source_id), hibernate_after: 5_000)
  end

  def do_snapshots(source_id), do: GenServer.cast(to_name(source_id), :do_snapshots)

  @impl true
  def init(id) do
    {:ok, %{id: id, module: Catalog.module_from_source_id(id), source: Catalog.get_source(id)}}
  end

  @impl true
  def handle_cast(:do_snapshots, state) do
    {:noreply, state, {:continue, :snapshot}}
  end

  @impl true
  def handle_continue(:snapshot, state = %{source: source}) do
    case SnapshotsServer.snapshot(state.module, source) do
      {:ok, snap} ->
        {:noreply, state |> Map.put(:snapshot, snap), {:continue, {:snapshot, :parsing}}}

      {:error, :timeout} ->
        log(:info, state, "retrying snapshot")
        {:noreply, state, {:continue, :snapshot}}

      {:error, e} ->
        log(:warning, state, "Error while doing snapshot : #{Utils.inspect_error(e)}")

        {:noreply, state}
    end
  end

  def handle_continue({:snapshot, :parsing}, state = %{snapshot: snap}) do
    case ParsingServer.parse(snap, state.module) do
      {:ok, parsed} ->
        {:noreply, state |> Map.put(:parsed_snapshot, parsed), {:continue, {:snapshot, :slicing}}}

      {:error, e} ->
        log(:warning, state, "Error while parsing snapshot : #{Utils.inspect_error(e)}")

        {:noreply, state}
    end
  end

  def handle_continue({:snapshot, :slicing}, state = %{parsed_snapshot: parsed}) do
    case ParsingServer.slice(parsed, state.module) do
      {:ok, new_slices} ->
        {:noreply, state |> Map.put(:slices, new_slices) |> Map.put(:slices_recognized, []),
         {:continue, {:snapshot, :entities_recognition}}}

      {:error, e} ->
        log(:warning, state, "Error while slicing snapshot : #{Utils.inspect_error(e)}")

        {:noreply, state}
    end
  end

  def handle_continue({:snapshot, :entities_recognition}, state = %{slices: []}),
    do: {:noreply, state, {:continue, {:snapshot, :final}}}

  def handle_continue(
        {:snapshot, :entities_recognition},
        state = %{slices: [slice | slices_tail], slices_recognized: slices}
      ) do
    case EntityRecognitionServer.recognize_entities(slice, state.module) do
      entities when is_list(entities) ->
        {:noreply, %{state | slices: slices_tail, slices_recognized: slices ++ [slice]},
         {:continue, {:snapshot, :entities_recognition}}}
    end
  end

  def handle_continue({:snapshot, :final}, state = %{slices_recognized: slices}) do
    PubSub.broadcast("snapshots:#{state.id}", state.snapshot)
    PubSub.broadcast("parsing:#{state.id}", state.parsed_snapshot)
    slices |> Enum.each(&PubSub.broadcast("slicing:#{state.id}", &1))

    {:noreply,
     state
     |> Map.delete(:snapshot)
     |> Map.delete(:parsed_snapshot)
     |> Map.delete(:slices)
     |> Map.delete(:slices_recognized)}
  end

  defp to_name(source_id), do: :"#{__MODULE__}.#{source_id}"

  defp log(level, state, msg), do: Logger.log(level, "#{state.id}/#{state.module}: #{msg}")
end
