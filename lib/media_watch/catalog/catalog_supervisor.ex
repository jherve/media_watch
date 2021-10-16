defmodule MediaWatch.Catalog.CatalogSupervisor do
  use Supervisor
  alias MediaWatch.Catalog.{ItemSupervisor, SourceSupervisor}

  def start_link(init_arg) do
    Supervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @impl true
  def init(_init_arg) do
    children = [SourceSupervisor, ItemSupervisor]

    Supervisor.init(children, strategy: :rest_for_one)
  end
end
