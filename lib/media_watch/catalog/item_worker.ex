defmodule MediaWatch.Catalog.ItemWorker do
  use GenServer
  require Logger
  alias MediaWatch.{PubSub, Analysis, Utils}
  alias MediaWatch.Catalog.{Item, SourceSupervisor, SourceWorker}
  alias MediaWatch.Parsing.Slice
  alias MediaWatch.Analysis.{ShowOccurrencesServer, ItemDescriptionServer}

  def start_link(module) when is_atom(module) do
    GenServer.start_link(__MODULE__, module, name: module, hibernate_after: 5_000)
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
  rescue
    _e in Exqlite.Error ->
      Logger.warning("Could not start #{module}")
      {:ok, nil}
  end

  def init(item = %Item{id: id}, module) do
    sources = item.sources
    source_ids = sources |> Enum.map(& &1.id)
    source_ids |> Enum.each(&PubSub.subscribe("slicing:#{&1}"))
    source_ids |> Enum.each(&SourceSupervisor.start/1)

    {:ok, %{id: id, module: module, item: item, sources: sources}}
  end

  @impl true
  def handle_cast(:do_snapshots, state = %{sources: sources}) do
    sources |> Enum.map(& &1.id) |> Enum.each(&SourceWorker.do_snapshots(&1))
    {:noreply, state}
  end

  @impl true
  def handle_info(slice = %Slice{}, state) do
    type = slice |> Analysis.classify(state.module)

    next_step =
      cond do
        type in [:show_occurrence_description, :show_occurrence_excerpt] -> :occurrence_detection
        type == :item_description -> :item_description
        true -> raise "Unknown type"
      end

    {:noreply, state |> Map.put(:slice, slice) |> Map.put(:slice_type, type),
     {:continue, next_step}}
  end

  @impl true
  def handle_continue(:occurrence_detection, state = %{slice: slice, slice_type: type}) do
    case ShowOccurrencesServer.detect_occurrence(slice, state.item.show.id, type, state.module) do
      {:ok, occ} ->
        {:noreply, state |> Map.put(:occurrence, occ), {:continue, :add_details}}

      e = {:error, _} ->
        log(:warning, state, Utils.inspect_error(e))
        {:noreply, state}
    end
  end

  def handle_continue(
        :add_details,
        state = %{slice: slice, occurrence: occ, slice_type: :show_occurrence_description}
      ) do
    case ShowOccurrencesServer.add_details(occ, slice) do
      {:ok, _} ->
        {:noreply, state, {:continue, :guest_detection}}

      e = {:error, _} ->
        log(:warning, state, Utils.inspect_error(e))
        {:noreply, state}
    end
  end

  def handle_continue(:add_details, state = %{slice_type: _}),
    do: {:noreply, state, {:continue, :guest_detection}}

  def handle_continue(:guest_detection, state = %{occurrence: occ}) do
    case ShowOccurrencesServer.do_guest_detection(occ, state.module) do
      guests when is_list(guests) ->
        {:noreply, state}

      e = {:error, _} ->
        log(:warning, state, Utils.inspect_error(e))
        {:noreply, state}
    end
  end

  def handle_continue(:item_description, state = %{slice: slice, slice_type: type}) do
    case ItemDescriptionServer.do_description(state.id, slice, type, state.module) do
      {:ok, _} -> nil
      e = {:error, _} -> log(:warning, state, Utils.inspect_error(e))
    end

    {:noreply, state}
  end

  defp log(level, state, msg), do: Logger.log(level, "#{state.module}: #{msg}")
end
