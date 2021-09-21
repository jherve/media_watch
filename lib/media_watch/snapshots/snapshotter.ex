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
    {:ok, nil}
  end

  @impl true
  def handle_cast({:do_snapshots, item_id}, state) do
    Catalog.select_sources(item_id)
    |> Repo.all()
    |> Enum.each(&start_run_and_publish/1)

    {:noreply, state}
  end

  def handle_cast(:do_all_snapshots, state) do
    Catalog.select_all_sources()
    |> Repo.all()
    |> Enum.each(&start_run_and_publish/1)

    {:noreply, state}
  end

  defp start_run_and_publish(source), do: Task.start(fn -> source |> run_and_publish end)

  defp run_and_publish(source),
    do:
      source
      |> Snapshots.run_snapshot_job()
      |> publish_results()

  defp publish_results({:ok, snap = %Snapshot{}}) do
    PubSub.broadcast("snapshots", snap)
  end
end
