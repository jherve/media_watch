defmodule MediaWatch.Catalog.ItemWorker do
  use GenServer
  require Logger
  alias MediaWatch.{PubSub, Analysis, Utils, Scheduler}
  alias MediaWatch.Catalog.{Item, SourceSupervisor, SourceWorker}
  alias MediaWatch.Parsing.Slice
  alias MediaWatch.Analysis.{ShowOccurrencesServer, ItemDescriptionServer}
  alias __MODULE__
  @snapshot_fields [snapshots_pending: MapSet.new()]
  @slice_analysis_fields [:slice, :slice_type]
  @occurrence_analysis_fields [:occurrence]

  defstruct [:id, :module, :item, :sources] ++
              @snapshot_fields ++ @slice_analysis_fields ++ @occurrence_analysis_fields

  def start_link(module) when is_atom(module) do
    GenServer.start_link(__MODULE__, module, name: module, hibernate_after: 5_000)
  end

  @doc "Require snapshot to be taken after `after_` seconds"
  def do_snapshots(module, after_ \\ 0), do: GenServer.cast(module, {:do_snapshots, after_})

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
    source_ids |> Enum.each(&PubSub.subscribe("source:#{&1}"))
    source_ids |> Enum.each(&SourceSupervisor.start/1)

    {:ok, %ItemWorker{id: id, module: module, item: item, sources: sources},
     {:continue, :after_init}}
  end

  @impl true
  def handle_cast({:do_snapshots, 0}, state) do
    do_snapshot_on_all_sources(state)
    {:noreply, state}
  end

  def handle_cast({:do_snapshots, duration}, state) when is_integer(duration) do
    timer = Process.send_after(self(), :do_snapshots, duration * 1_000)
    {:noreply, update_in(state.snapshots_pending, &(&1 |> MapSet.put(timer)))}
  end

  @impl true
  def handle_info(:do_snapshots, state) do
    do_snapshot_on_all_sources(state)
    {:noreply, update_in(state.snapshots_pending, &clear_expired_timers/1)}
  end

  def handle_info(slice = %Slice{}, state) do
    type = slice |> Analysis.classify(state.module)

    pipeline =
      case type do
        :show_occurrence_description -> :occurrence_description_analysis
        :show_occurrence_excerpt -> :occurrence_excerpt_analysis
        :item_description -> :item_description_analysis
        true -> raise "Unknown type"
      end

    {:noreply, state |> Map.put(:slice, slice) |> Map.put(:slice_type, type),
     {:continue, pipeline}}
  end

  @impl true
  def handle_continue(:after_init, state = %{module: module}) do
    job_name = :"#{module}.Snapshot"

    Scheduler.delete_job(job_name)
    setup_cron_job(module, job_name)

    {:noreply, state}
  end

  def handle_continue(pipeline = :occurrence_description_analysis, state) do
    {:noreply, state, {:continue, {pipeline, :occurrence_detection}}}
  end

  def handle_continue(pipeline = :occurrence_excerpt_analysis, state) do
    {:noreply, state, {:continue, {pipeline, :occurrence_detection}}}
  end

  def handle_continue(
        stage = {_, :occurrence_detection},
        state = %{slice: slice, slice_type: type}
      ) do
    case ShowOccurrencesServer.detect_occurrence(slice, state.item.show.id, type, state.module) do
      {:ok, occ} ->
        {:noreply, state |> Map.put(:occurrence, occ), {:continue, next_stage(stage)}}

      e = {:error, _} ->
        log(:warning, state, Utils.inspect_error(e))
        {:noreply, state}
    end
  end

  def handle_continue(
        {pipeline, :add_details},
        state = %{slice: slice, occurrence: occ}
      ) do
    case ShowOccurrencesServer.add_details(occ, slice) do
      {:ok, _} ->
        {:noreply, state, {:continue, {pipeline, :guest_detection}}}

      e = {:error, _} ->
        log(:warning, state, Utils.inspect_error(e))
        {:noreply, state}
    end
  end

  def handle_continue({pipeline, :guest_detection}, state = %{occurrence: occ}) do
    case ShowOccurrencesServer.do_guest_detection(occ, state.module) do
      guests when is_list(guests) ->
        {:noreply, state, {:continue, {pipeline, :final}}}

      e = {:error, _} ->
        log(:warning, state, Utils.inspect_error(e))
        {:noreply, state}
    end
  end

  def handle_continue({:occurrence_description_analysis, :final}, state) do
    publish_show_occurrence(state)
    {:noreply, state |> reset(@slice_analysis_fields ++ @occurrence_analysis_fields)}
  end

  def handle_continue({:occurrence_excerpt_analysis, :final}, state) do
    publish_show_occurrence(state)
    {:noreply, state |> reset(@slice_analysis_fields ++ @occurrence_analysis_fields)}
  end

  def handle_continue(:item_description_analysis, state = %{slice: slice, slice_type: type}) do
    case ItemDescriptionServer.do_description(state.id, slice, type, state.module) do
      {:ok, desc} -> PubSub.broadcast("item:#{state.id}", desc)
      e = {:error, _} -> log(:warning, state, Utils.inspect_error(e))
    end

    {:noreply, state |> reset(@slice_analysis_fields)}
  end

  defp setup_cron_job(module, job_name) do
    duration = module.get_duration()
    # To stay on the safe side and account for the time it takes for information
    # to be published, the snapshot is taken with an additional delay after the
    # end of the show.
    #
    # TODO: Find a more-bulletproof solution that allows to "poll" waiting for a
    # new snapshot.
    snap_delay = if duration < 60 * 15, do: duration * 2, else: duration * 1.5

    Scheduler.new_job()
    |> Quantum.Job.set_name(job_name)
    |> Quantum.Job.set_schedule(module.get_airing_schedule())
    |> Quantum.Job.set_timezone(module.get_time_zone() |> Timex.Timezone.name_of())
    |> Quantum.Job.set_task({ItemWorker, :do_snapshots, [module, round(snap_delay)]})
    |> Scheduler.add_job()
  end

  defp do_snapshot_on_all_sources(%{sources: sources}),
    do: sources |> Enum.map(& &1.id) |> Enum.each(&SourceWorker.do_snapshots(&1))

  defp clear_expired_timers(timers = %MapSet{}),
    do: timers |> Enum.filter(&(&1 |> Process.read_timer())) |> MapSet.new()

  defp next_stage({p = :occurrence_description_analysis, :occurrence_detection}),
    do: {p, :add_details}

  defp next_stage({p = :occurrence_excerpt_analysis, :occurrence_detection}),
    do: {p, :guest_detection}

  defp log(level, state, msg), do: Logger.log(level, "#{state.module}: #{msg}")

  defp reset(state, fields) when is_list(fields),
    do: struct(ItemWorker, state |> Map.from_struct() |> Map.drop(fields))

  defp publish_show_occurrence(state),
    do: PubSub.broadcast("item:#{state.id}", state.occurrence)
end
