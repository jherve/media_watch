defmodule MediaWatch.Parsing.Parser do
  use GenServer
  alias MediaWatch.PubSub
  alias MediaWatch.Snapshots.Snapshot
  alias MediaWatch.Parsing.{Job, ParsedSnapshot}
  @name MediaWatch.Parsing.Parser

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: @name)
  end

  @impl true
  def init(_opts) do
    PubSub.subscribe("snapshots")
    {:ok, nil}
  end

  @impl true
  def handle_info(snap = %Snapshot{}, state) do
    %Job{snapshot: snap} |> Job.run() |> publish_results()
    {:noreply, state}
  end

  defp publish_results({:ok, parsed = %ParsedSnapshot{}}) do
    PubSub.broadcast("parsing", parsed)
  end
end
