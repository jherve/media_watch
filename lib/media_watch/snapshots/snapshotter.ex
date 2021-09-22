defmodule MediaWatch.Snapshots.Snapshotter do
  use GenServer
  alias MediaWatch.{Repo, Catalog, PubSub, Snapshots}
  alias MediaWatch.Snapshots.Snapshot
  @name MediaWatch.Snapshots.Snapshotter

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: @name)
  end

  def do_snapshots(item_id), do: GenServer.cast(@name, {:do_snapshots, item_id})
  def do_all_snapshots(), do: GenServer.cast(@name, :do_all_snapshots)

  @impl true
  def init(_opts) do
    {:ok, %{tasks: %{}}}
  end

  @impl true
  def handle_cast({:do_snapshots, item_id}, state) do
    tasks_map =
      Catalog.select_sources(item_id)
      |> Repo.all()
      |> Map.new(&start_run_and_publish/1)

    {:noreply, state |> merge_tasks(tasks_map)}
  end

  def handle_cast(:do_all_snapshots, state) do
    tasks_map =
      Catalog.select_all_sources()
      |> Repo.all()
      |> Map.new(&start_run_and_publish/1)

    {:noreply, state |> merge_tasks(tasks_map)}
  end

  @impl true
  def handle_info({ref, :ok}, state) do
    # A snapshot task has completed successfully
    Process.demonitor(ref, [:flush])
    {:noreply, state |> ack_task(ref)}
  end

  def handle_info({ref, {:error, %{reason: :timeout}}}, state) do
    # A snapshot task has timed out
    Process.demonitor(ref, [:flush])
    # Another snapshot task for the same source is started to try and finish the job
    # TODO : We should somehow limit the number of possible retries
    {retry_ref, source} = state.tasks |> Map.get(ref) |> start_run_and_publish()
    {:noreply, state |> ack_task(ref) |> add_task(retry_ref, source)}
  end

  def handle_info({:DOWN, ref, _, _, reason}, state) do
    # A snapshot task has crashed
    {retry_ref, source} = state.tasks |> Map.get(ref) |> start_run_and_publish()
    {:noreply, state |> ack_task(ref) |> add_task(retry_ref, source)}
  end

  defp add_task(state, ref, source),
    do: state |> Map.update!(:tasks, &(&1 |> Map.put(ref, source)))

  defp merge_tasks(state, tasks_map) when is_map(tasks_map),
    do: state |> Map.update!(:tasks, &(&1 |> Map.merge(tasks_map)))

  defp ack_task(state, task_ref) when is_reference(task_ref),
    do: state |> Map.update!(:tasks, &(&1 |> Map.delete(task_ref)))

  defp start_run_and_publish(source) do
    # See https://hexdocs.pm/elixir/1.12/Task.html#await/2-compatibility-with-otp-behaviours
    # for justification of the use of Task.Supervisor and async_nolink.
    task =
      Task.Supervisor.async_nolink(MediaWatch.TaskSupervisor, fn -> source |> run_and_publish end)

    {task.ref, source}
  end

  defp run_and_publish(source) do
    case source |> Snapshots.run_snapshot_job() do
      {:ok, snap = %Snapshot{}} -> PubSub.broadcast("snapshots", snap)
      error = {:error, _} -> error
    end
  end
end
