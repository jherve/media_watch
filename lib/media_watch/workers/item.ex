defmodule MediaWatch.Catalog.ItemWorker do
  use GenServer
  require Logger
  alias MediaWatch.{Catalog, PubSub, Analysis, Utils, Scheduler}
  alias MediaWatch.Catalog.{Item, SourceSupervisor, SourceWorker}
  alias MediaWatch.Parsing.Slice
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
    case Catalog.get_item_from_module(module) do
      nil ->
        Logger.warning("Could not start #{module}")
        {:ok, nil}

      item ->
        item |> init(module)
    end
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

    case type do
      :show_occurrence_description ->
        run_occurrence_pipeline(state, slice, type, true)
        {:noreply, state}

      :show_occurrence_excerpt ->
        run_occurrence_pipeline(state, slice, type, false)
        {:noreply, state}

      :item_description ->
        run_description_pipeline(state, slice, type)
        {:noreply, state}

      true ->
        raise "Unknown type"
    end
  end

  defp run_occurrence_pipeline(state, slice, type, run_details?) do
    case Analysis.run_occurrence_pipeline(slice, type, state.module, run_details?) do
      {:ok, %{occurrence: occ}} -> PubSub.broadcast("item:#{state.id}", occ)
      {:error, step, e} -> log(:warning, state, "(#{step}) #{Utils.inspect_error(e)}")
    end
  end

  defp run_description_pipeline(state, slice, type) do
    case Analysis.run_description_pipeline(slice, type, state.module) do
      {:ok, %{description: desc}} -> PubSub.broadcast("item:#{state.id}", desc)
      {:ok, %{}} -> nil
      {:error, e} -> log(:warning, state, Utils.inspect_error(e))
    end
  end

  @impl true
  def handle_continue(:after_init, state = %{module: module}) do
    job_name = :"#{module}.Snapshot"

    Scheduler.delete_job(job_name)
    setup_cron_job(module, job_name)

    {:noreply, state}
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

  defp log(level, state, msg), do: Logger.log(level, "#{state.module}: #{msg}")
end
