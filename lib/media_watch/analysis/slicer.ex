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

  defp publish_results(facets_list) when is_list(facets_list) do
    # Broadcast one message per facet on a generic topic
    facets_list
    |> Enum.each(&PubSub.broadcast("slicing", &1))

    # Broadcast a message containing all the new facets of each source
    # onto a specific topic
    facets_list
    |> Enum.group_by(& &1.source_id)
    |> Enum.each(fn {source_id, facets} ->
      PubSub.broadcast("slicing:#{source_id}", {:new_facets, facets})
    end)
  end
end
