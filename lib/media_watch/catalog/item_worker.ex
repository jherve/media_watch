defmodule MediaWatch.Catalog.ItemWorker do
  use GenServer
  require Logger
  alias MediaWatch.{PubSub, Parsing, Analysis}
  alias MediaWatch.Catalog.{Item, SourceSupervisor, SourceWorker}
  alias MediaWatch.Parsing.Slice
  alias MediaWatch.Analysis.ShowOccurrence

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
    PubSub.subscribe("occurrence_formatting:#{id}")
    sources = item.sources
    source_ids = sources |> Enum.map(& &1.id)
    source_ids |> Enum.each(&PubSub.subscribe("slicing:#{&1}"))
    source_ids |> Enum.each(&SourceSupervisor.start/1)

    {:ok,
     %{
       id: id,
       module: module,
       item: item,
       sources: sources,
       description: id |> Analysis.get_description(),
       occurrences: item.show.id |> Analysis.get_occurrences(),
       slices: Parsing.get_slices(source_ids)
     }, {:continue, :do_catchup}}
  end

  @impl true
  def handle_continue(:do_catchup, state) do
    attempt_catchup(state, :slices)
    {:noreply, state}
  end

  @impl true
  def handle_cast(:do_snapshots, state = %{sources: sources}) do
    sources |> Enum.map(& &1.id) |> Enum.each(&SourceWorker.do_snapshots(&1))
    {:noreply, state}
  end

  @impl true
  def handle_info(slice = %Slice{}, state), do: handle_slice(slice, state)
  def handle_info(occ = %ShowOccurrence{}, state), do: handle_show_occurrence(occ, state)

  defp handle_slice(slice = %Slice{type: :rss_channel_description}, state = %{module: module}) do
    case slice |> Analysis.create_description_and_store(module.get_repo(), module) do
      {:ok, desc} ->
        PubSub.broadcast("description:#{state.id}", desc)
        {:noreply, %{state | description: desc}}

      {:error, _} ->
        {:noreply, state}
    end
  end

  defp handle_slice(slice = %Slice{type: :rss_entry}, state = %{module: module}) do
    repo = module.get_repo()

    case slice |> Analysis.create_occurrence_and_store(repo, module) do
      {:ok, new_occ} ->
        PubSub.broadcast("occurrence_formatting:#{state.id}", new_occ)
        {:noreply, update_in(state.occurrences, &append(&1, new_occ))}

      {:error, {:unique_airing_time, occ}} ->
        case Analysis.update_occurrence_and_store(occ, slice, repo, module) do
          {:ok, updated} ->
            PubSub.broadcast("occurrence_formatting:#{state.id}", updated)
            {:noreply, update_in(state.occurrences, &refresh(&1, updated))}

          {:error, _} ->
            {:noreply, state}
        end

      {:error, reason} ->
        Logger.warning(
          "#{__MODULE__} could not handle slice #{slice.id} because : #{inspect(reason)}"
        )

        {:noreply, state}
    end
  end

  defp handle_show_occurrence(occ = %ShowOccurrence{}, state = %{module: module}) do
    ok_res =
      occ
      |> Analysis.insert_guests_from(module.get_repo(), module)
      |> Enum.filter(&match?({:ok, _}, &1))

    ok_res |> Enum.each(&PubSub.broadcast("invitation:#{state.id}", &1))
    {:noreply, state}
  end

  defp append(list, elem) when is_list(list), do: list ++ [elem]

  defp refresh(list, elem) when is_list(list) do
    with current_idx when not is_nil(current_idx) <- list |> Enum.find_index(&(&1.id == elem.id)),
         do: list |> List.replace_at(current_idx, elem)
  end

  defp attempt_catchup(state, :slices) do
    description_as_list = if desc = state.description, do: [desc], else: []

    slices_seen_ids =
      (description_as_list ++ state.occurrences)
      |> Enum.flat_map(& &1.slices)
      |> Enum.map(& &1.id)

    state.slices
    |> Enum.reject(&(&1.id in slices_seen_ids))
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

  defp catchup(slice = %Slice{}, state), do: handle_slice(slice, state)

  defp log_catching_up([]), do: nil

  defp log_catching_up(list = [%obj_type{} | _]) when is_list(list),
    do:
      Logger.info("Catching up on #{obj_type} [#{list |> Enum.map(& &1.id) |> Enum.join(", ")}]")
end
