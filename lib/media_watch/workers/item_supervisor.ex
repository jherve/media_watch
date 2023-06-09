defmodule MediaWatch.Catalog.ItemSupervisor do
  use Supervisor
  require Logger
  alias MediaWatch.Catalog.ItemWorker

  def start_link(init_arg) do
    Supervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @impl true
  def init(_init_arg) do
    children =
      MediaWatchInventory.all() |> Enum.map(&Supervisor.child_spec({ItemWorker, &1}, id: &1))

    Supervisor.init(children, strategy: :one_for_one)
  end
end
