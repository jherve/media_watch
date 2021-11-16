defmodule MediaWatch.Snapshots.SnapshotsServer do
  use MediaWatch.AsyncGenServer
  require Logger
  alias MediaWatch.Telemetry
  alias MediaWatch.Snapshots.SnapshotOperation
  @name __MODULE__
  @prefix [:media_watch, :snapshots_server]

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: @name)
  end

  def snapshot(module, source),
    do:
      fn -> GenServer.call(@name, {:do_snapshot, module, source}, :infinity) end
      |> Telemetry.span_function_call(@prefix ++ [:snapshot], %{module: module})

  @impl true
  def init([]), do: {:ok, AsyncGenServer.init_state()}

  @impl true
  def handle_call({:do_snapshot, _module, source}, pid, state) do
    fn -> {pid, do_snapshot(source)} end
    |> AsyncGenServer.start_async_task(state)
  end

  defp do_snapshot(source),
    do:
      SnapshotOperation.new(source)
      |> SnapshotOperation.set_retry_strategy(fn
        :snap_timeout, nb_retries -> if nb_retries < 5, do: :retry, else: :abort
        :database_busy, _ -> :retry_exp
      end)
      |> SnapshotOperation.run()

  @impl true
  def handle_task_end(_, {pid, ok_or_error}, _, state) do
    GenServer.reply(pid, ok_or_error)
    {:remove, state}
  end
end
