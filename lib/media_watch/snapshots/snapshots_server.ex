defmodule MediaWatch.Snapshots.SnapshotsServer do
  use MediaWatch.AsyncGenServer
  require Logger
  alias MediaWatch.{Snapshots, Telemetry, Repo}
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
  def handle_call({:do_snapshot, module, source}, pid, state) do
    fn -> {pid, Snapshots.make_snapshot_and_insert(source)} end
    |> Repo.rescue_if_busy({pid, {:error, :database_busy}})
    |> AsyncGenServer.start_async_task(state, module: module)
  end

  @impl true
  def handle_task_end(_, {pid, {:error, %{reason: :timeout}}}, state) do
    GenServer.reply(pid, {:error, :timeout})
    {:remove, state}
  end

  def handle_task_end(_, {_, {:error, :database_busy}}, state), do: {:retry, state}

  def handle_task_end(_, {pid, ok_or_error}, state) do
    GenServer.reply(pid, ok_or_error)
    {:remove, state}
  end
end
