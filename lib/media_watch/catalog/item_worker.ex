defmodule MediaWatch.Catalog.ItemWorker do
  use GenServer
  require Logger
  alias MediaWatch.{PubSub, Parsing, Analysis}
  alias MediaWatch.Catalog.{Item, SourceSupervisor, SourceWorker}
  alias MediaWatch.Parsing.Slice
  alias MediaWatch.Analysis.{ShowOccurrence, Description}

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
    sources = item.sources
    occurrences = item.show.id |> Analysis.get_occurrences()
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
       occurrences: occurrences,
       slices: Parsing.get_slices(source_ids),
       slice_usages: occurrences |> Enum.flat_map(& &1.slice_usages),
       details: occurrences |> Enum.map(& &1.detail)
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
  def handle_info(slice = %Slice{}, state),
    do: handle_slice(slice, state, slice |> Analysis.classify(state.module))

  defp handle_slice(slice, state, type = :show_occurrence_description) do
    # TODO: Publish results
    with {:ok, occ, state} <- do_occurrence_detection(slice, state),
         {:ok, _, state} <- mark_slice_usage(slice, occ, type, state),
         {:ok, _, state} <- add_details(occ, slice, state),
         guests when is_list(guests) <- do_guest_detection(occ, state) do
      {:noreply, state}
    else
      e = {:error, _} ->
        Logger.warning(inspect(e))
        {:noreply, state}
    end
  end

  defp handle_slice(slice, state, type = :item_description) do
    with {:ok, desc, state} <- do_description(slice, state),
         {:ok, _, state} <- mark_slice_usage(slice, desc, type, state) do
      {:noreply, state}
    else
      e = {:error, _} ->
        Logger.warning(inspect(e))
        {:noreply, state}
    end
  end

  defp handle_slice(slice, state, type = :show_occurrence_excerpt) do
    with {:ok, occ, state} <- do_occurrence_detection(slice, state),
         {:ok, _, state} <- mark_slice_usage(slice, occ, type, state),
         guests when is_list(guests) <- do_guest_detection(occ, state) do
      {:noreply, state}
    else
      e = {:error, _} ->
        Logger.warning(inspect(e))
        {:noreply, state}
    end
  end

  defp do_occurrence_detection(slice, state) do
    repo = state.module.get_repo()

    with {:ok, date} <- slice |> Analysis.extract_date(),
         time_slot <- date |> state.module.get_time_slot(),
         airing_time when is_struct(airing_time, DateTime) <- state.module.get_airing_time(date),
         {:ok, occ} <-
           Analysis.create_occurrence(state.item.show.id, airing_time, time_slot)
           |> MediaWatch.Repo.insert_and_retry(repo)
           |> Analysis.explain_create_occurrence_error() do
      {:ok, occ, update_in(state.occurrences, &append(&1, occ))}
    else
      {:error, {:unique, occ}} -> {:ok, occ, state}
      e = {:error, _} -> e
    end
  end

  defp mark_slice_usage(slice, %ShowOccurrence{id: id}, type, state) do
    repo = state.module.get_repo()

    with {:ok, usage} <-
           Analysis.create_slice_usage(slice.id, id, type)
           |> MediaWatch.Repo.insert_and_retry(repo),
         do: {:ok, usage, update_in(state.slice_usages, &append(&1, usage))}
  end

  defp mark_slice_usage(slice, %Description{item_id: id}, type, state) do
    repo = state.module.get_repo()

    with {:ok, usage} <-
           Analysis.create_slice_usage(slice.id, id, type)
           |> MediaWatch.Repo.insert_and_retry(repo),
         do: {:ok, usage, update_in(state.slice_usages, &append(&1, usage))}
  end

  defp add_details(occurrence, slice, state) do
    repo = state.module.get_repo()

    case Analysis.create_occurrence_details(occurrence.id, slice)
         |> MediaWatch.Repo.insert_and_retry(repo)
         |> Analysis.explain_create_occurrence_detail_error() do
      {:ok, detail} ->
        {:ok, detail, update_in(state.details, &append(&1, detail))}

      {:error, {:unique, existing}} ->
        add_details_via_update(existing, slice, state)

      e = {:error, _} ->
        e
    end
  end

  defp add_details_via_update(occurrence, slice, state) do
    repo = state.module.get_repo()

    case Analysis.update_occurrence_details(occurrence, slice)
         |> MediaWatch.Repo.update_and_retry(repo) do
      {:ok, updated} ->
        {:ok, updated, update_in(state.details, &refresh(&1, updated))}

      {:error, e} ->
        {:error, e, state}
    end
  end

  defp do_guest_detection(occ = %ShowOccurrence{}, %{module: module}) do
    occ
    |> Analysis.insert_guests_from(module.get_repo(), module)
    |> Enum.filter(&match?({:ok, _}, &1))
  end

  defp do_description(slice, state) do
    repo = state.module.get_repo()

    with {:ok, desc} <-
           Analysis.create_description(state.id, slice, state.module)
           |> MediaWatch.Repo.insert_and_retry(repo),
         do: {:ok, desc, %{state | description: desc}}
  end

  defp append(list, elem) when is_list(list), do: list ++ [elem]

  defp refresh(list, elem) when is_list(list) do
    with current_idx when not is_nil(current_idx) <- list |> Enum.find_index(&(&1.id == elem.id)),
         do: list |> List.replace_at(current_idx, elem)
  end

  defp attempt_catchup(state, :slices) do
    slices_seen_ids = state.slice_usages |> Enum.map(& &1.slice_id)

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

  defp catchup(slice = %Slice{}, state),
    do: handle_slice(slice, state, slice |> Analysis.classify(state.module))

  defp log_catching_up([]), do: nil

  defp log_catching_up(list = [%obj_type{} | _]) when is_list(list),
    do:
      Logger.info("Catching up on #{obj_type} [#{list |> Enum.map(& &1.id) |> Enum.join(", ")}]")
end
