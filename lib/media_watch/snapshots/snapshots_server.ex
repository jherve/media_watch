defmodule MediaWatch.Snapshots.SnapshotsServer do
  use MediaWatch.AsyncGenServer
  require Logger
  alias MediaWatch.{Snapshots, Telemetry}
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
    fn ->
      with ok = {:ok, _} <- Snapshots.make_snapshot_and_insert(source) do
        GenServer.reply(pid, ok)
      else
        {:error, %{reason: :timeout}} -> GenServer.reply(pid, {:error, :timeout})
        e = {:error, _} -> GenServer.reply(pid, e)
      end
    end
    |> AsyncGenServer.start_async_task(state, module: module)
  end
end
