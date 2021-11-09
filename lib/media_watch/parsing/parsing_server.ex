defmodule MediaWatch.Parsing.ParsingServer do
  use MediaWatch.AsyncGenServer
  require Logger
  alias MediaWatch.{Parsing, Telemetry}
  alias MediaWatch.Snapshots.Snapshot
  alias MediaWatch.Parsing.ParsedSnapshot
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
    fn ->
      GenServer.reply(pid, snap |> Parsing.parse_and_insert(module))
    end
    |> AsyncGenServer.start_async_task(state)
  end

  def handle_call({:slice, parsed = %ParsedSnapshot{}, module}, pid, state) do
    fn ->
      new_slices =
        case Parsing.get(parsed.id) |> Parsing.slice_and_insert(module) do
          {:ok, ok, _} ->
            ok

          {:error, ok, _, errors} ->
            Logger.warning("#{errors |> Enum.count()} errors on slices insertion in #{module}")
            ok
        end

      GenServer.reply(pid, {:ok, new_slices})
    end
    |> AsyncGenServer.start_async_task(state)
  end
end
