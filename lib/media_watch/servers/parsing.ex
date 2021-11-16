defmodule MediaWatch.Parsing.ParsingServer do
  use MediaWatch.AsyncGenServer
  require Logger
  alias MediaWatch.{Parsing, Telemetry}
  alias MediaWatch.Snapshots.Snapshot
  alias MediaWatch.Parsing.{ParsedSnapshot, ParsingOperation, SlicingOperation}
  @name __MODULE__
  @prefix [:media_watch, :parsing_server]

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: @name)
  end

  def parse(snap, module),
    do:
      fn -> GenServer.call(@name, {:parse, snap, module}, :infinity) end
      |> Telemetry.span_function_call(@prefix ++ [:parse], %{module: module})

  def slice(parsed, module),
    do:
      fn -> GenServer.call(@name, {:slice, parsed, module}, :infinity) end
      |> Telemetry.span_function_call(@prefix ++ [:slice], %{module: module})

  @impl true
  def init([]), do: {:ok, AsyncGenServer.init_state(%{parsed_snapshots: [], slices: []})}

  @impl true
  def handle_call({:parse, snap = %Snapshot{}, module}, pid, state) do
    fn -> {:parse, pid, do_parsing(snap, module)} end
    |> AsyncGenServer.start_async_task(state)
  end

  def handle_call({:slice, parsed = %ParsedSnapshot{}, module}, pid, state) do
    fn -> {:slice, pid, module, Parsing.get(parsed.id) |> do_slicing(module)} end
    |> AsyncGenServer.start_async_task(state)
  end

  defp do_parsing(snap, parsable),
    do:
      ParsingOperation.new(snap, parsable)
      |> ParsingOperation.set_retry_strategy(fn :database_busy, _ -> :retry_exp end)
      |> ParsingOperation.run()

  defp do_slicing(parsed, sliceable),
    do:
      SlicingOperation.new(parsed, sliceable)
      |> SlicingOperation.set_retry_strategy(fn :database_busy, _ -> :retry_exp end)
      |> SlicingOperation.run()

  @impl true
  def handle_task_end(_, {:parse, pid, res}, _, state) do
    GenServer.reply(pid, res)
    {:remove, state}
  end

  def handle_task_end(_, {:slice, pid, _, {:ok, ok, _}}, _, state) do
    GenServer.reply(pid, {:ok, ok})
    {:remove, state}
  end

  def handle_task_end(_, {:slice, pid, module, {:error, ok, _, errors}}, _, state) do
    Logger.warning("#{errors |> Enum.count()} errors on slices insertion in #{module}")
    GenServer.reply(pid, {:ok, ok})
    {:remove, state}
  end
end
