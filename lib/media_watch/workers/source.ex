defmodule MediaWatch.Catalog.SourceWorker do
  use GenServer
  require Logger
  alias MediaWatch.{Catalog, Snapshots, PubSub}
  alias __MODULE__

  defstruct [:id, :module, :source, :snapshot_command_date]

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
  def handle_cast(:do_snapshots, state = %{snapshot_command_date: command = %DateTime{}}) do
    time_since_last = DateTime.utc_now() |> DateTime.diff(command)

    log(
      :warning,
      state,
      "Dropping new snapshot command (another one is pending since #{time_since_last} seconds)"
    )

    {:noreply, state}
  end

  def handle_cast(:do_snapshots, state),
    do: %{state | snapshot_command_date: DateTime.utc_now()} |> do_snapshot(false)

  @impl true
  def handle_info(:snapshot_retry, state) do
    log(:debug, state, "Retrying to take snapshot..")
    do_snapshot(state, true)
  end

  defp do_snapshot(state, retry?) do
    with {:ok, %{slices: slices}} when slices != [] <-
           Snapshots.run_snapshot_pipeline(state.source, state.module) do
      slices |> Enum.each(&PubSub.broadcast("source:#{state.id}", &1))

      if retry? do
        time_since_command = DateTime.utc_now() |> DateTime.diff(state.snapshot_command_date)
        log(:info, state, "Snapshot retry success after #{time_since_command} seconds)")
      end

      {:noreply, %{state | snapshot_command_date: nil}}
    else
      {:error, :slicing, :no_new_slice} ->
        Process.send_after(self(), :snapshot_retry, retry_period())
        {:noreply, state}

      {:error, :snapshot, :unique_content} ->
        Process.send_after(self(), :snapshot_retry, retry_period())
        {:noreply, state}

      {:error, stage, reason} ->
        log(:warning, state, "Error during #{stage}: #{reason |> inspect}")
        {:noreply, %{state | snapshot_command_date: nil}}
    end
  end

  defp retry_period(),
    do: Application.get_env(:media_watch, SourceWorker) |> Keyword.get(:no_slice_retry_period)

  defp to_name(source_id), do: :"#{__MODULE__}.#{source_id}"

  defp log(level, state, msg), do: Logger.log(level, "#{state.id}/#{state.module}: #{msg}")
end
