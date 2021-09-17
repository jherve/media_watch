defmodule MediaWatch.Analysis.Slicer do
  use GenServer
  require Logger
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
    ok_res =
      case MediaWatch.Parsing.get(snap.id) |> Analysis.do_slicing() do
        {:ok, ok, _} ->
          ok

        {:error, ok, _, errors} ->
          Logger.error("#{errors |> Enum.count()} errors on facets insertion")
          ok
      end

    ok_res |> publish_results
    {:noreply, state}
  end

  defp publish_results(facets_list) when is_list(facets_list),
    do:
      facets_list
      |> Enum.each(&PubSub.broadcast("slicing", &1))
end
