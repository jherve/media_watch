defmodule MediaWatch.Catalog.CatalogSupervisor do
  use Supervisor
  require Logger
  alias MediaWatch.Catalog.{ItemSupervisor, SourceSupervisor}

  def start_link(init_arg) do
    case MediaWatchInventory.insert_all() do
      :ok ->
        Supervisor.start_link(__MODULE__, init_arg, name: __MODULE__)

      error ->
        Logger.error("Could not start CatalogSupervisor due to error : #{inspect(error)}")
        {:error, error}
    end
  end

  @impl true
  def init(_init_arg) do
    children = [SourceSupervisor, ItemSupervisor]

    Supervisor.init(children, strategy: :rest_for_one)
  end
end
