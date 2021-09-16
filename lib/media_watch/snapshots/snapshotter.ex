defmodule MediaWatch.Snapshots.Snapshotter do
  use GenServer
  alias MediaWatch.{Repo, Catalog, PubSub, Snapshots}
  alias MediaWatch.Snapshots.Snapshot
  @name MediaWatch.Snapshots.Snapshotter

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: @name)
  end

  def do_snapshots(item_id), do: GenServer.cast(@name, {:do_snapshots, item_id})

  @impl true
  def init(_opts) do
    {:ok, nil}
  end

  @impl true
  def handle_cast({:do_snapshots, item_id}, state) do
    Catalog.select_sources(item_id)
    |> Repo.all()
    |> Enum.map(&Snapshots.run_snapshot_job/1)
    |> Enum.map(&publish_results/1)

    {:noreply, state}
  end

  defp publish_results({:ok, snap = %Snapshot{}}) do
    PubSub.broadcast("snapshots", snap)
  end
end
