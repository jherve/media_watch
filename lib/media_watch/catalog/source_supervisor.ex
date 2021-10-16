defmodule MediaWatch.Catalog.SourceSupervisor do
  use DynamicSupervisor
  alias MediaWatch.Catalog.SourceWorker

  def start_link(init_arg) do
    DynamicSupervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  def start(source_id) do
    DynamicSupervisor.start_child(__MODULE__, {SourceWorker, source_id})
  end

  @impl true
  def init(_init_arg) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end
end
