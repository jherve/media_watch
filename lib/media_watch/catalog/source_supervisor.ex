defmodule MediaWatch.Catalog.SourceSupervisor do
  use DynamicSupervisor
  require Logger
  alias MediaWatch.Catalog.SourceWorker

  def start_link(init_arg) do
    DynamicSupervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  def start(source_id) do
    case DynamicSupervisor.start_child(__MODULE__, {SourceWorker, source_id}) do
      ok = {:ok, _} ->
        ok

      e = {:error, {:already_started, _}} ->
        Logger.info("SourceWorker #{source_id} is already started")
        e

      e = {:error, reason} ->
        Logger.warning("Could not start SourceWorker #{source_id} because : #{inspect(reason)}")
        e
    end
  end

  @impl true
  def init(_init_arg) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end
end
