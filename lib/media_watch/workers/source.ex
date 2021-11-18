defmodule MediaWatch.Catalog.SourceWorker do
  use GenServer
  require Logger
  alias MediaWatch.{Catalog, Snapshots, PubSub}
  alias __MODULE__

  defstruct [:id, :module, :source]

  def start_link(source_id) do
    # `hibernate_after` option is added in order to try and prevent
    # excessive memory usage. See:
    # https://elixirforum.com/t/extremely-high-memory-usage-in-genservers/4035/25
    GenServer.start_link(__MODULE__, source_id, name: to_name(source_id), hibernate_after: 5_000)
  end

  def do_snapshots(source_id), do: GenServer.cast(to_name(source_id), :do_snapshots)

  @impl true
  def init(id) do
    {:ok,
     %SourceWorker{
       id: id,
       module: Catalog.module_from_source_id(id),
       source: Catalog.get_source(id)
     }}
  end

  @impl true
  def handle_cast(:do_snapshots, state) do
    with {:ok, %{slices: slices}} <- Snapshots.run_snapshot_pipeline(state.source, state.module) do
      slices |> Enum.each(&PubSub.broadcast("source:#{state.id}", &1))
      {:noreply, state}
    else
      {:error, stage, reason} ->
        log(:warning, state, "Error during #{stage}: #{reason |> inspect}")
        {:noreply, state}
    end
  end

  defp to_name(source_id), do: :"#{__MODULE__}.#{source_id}"

  defp log(level, state, msg), do: Logger.log(level, "#{state.id}/#{state.module}: #{msg}")
end
