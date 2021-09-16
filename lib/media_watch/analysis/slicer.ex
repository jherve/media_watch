defmodule MediaWatch.Analysis.Slicer do
  use GenServer
  alias MediaWatch.{PubSub, Analysis}
  alias MediaWatch.Parsing.ParsedSnapshot
  @name MediaWatch.Analysis.Slicer

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: @name)
  end

  @impl true
  def init(_opts) do
    PubSub.subscribe("parsing")
    {:ok, nil}
  end

  @impl true
  def handle_info(snap = %ParsedSnapshot{}, state) do
    MediaWatch.Parsing.get(snap.id) |> Analysis.do_slicing() |> publish_results
    {:noreply, state}
  end

  defp publish_results({:ok, facets_map}) when is_map(facets_map) do
    facets_map
    |> Enum.each(fn {{:facet, _id}, facet} -> PubSub.broadcast("slicing", facet) end)
  end
end
