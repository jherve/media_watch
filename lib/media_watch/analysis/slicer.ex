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
          Logger.error("#{errors |> Enum.count()} errors on slices insertion")
          ok
      end

    ok_res |> publish_results
    {:noreply, state}
  end

  defp publish_results(slices_list) when is_list(slices_list) do
    # Broadcast one message per slice on a generic topic
    slices_list
    |> Enum.each(&PubSub.broadcast("slicing", &1))

    # Broadcast a message containing all the new slices of each source
    # onto a specific topic
    slices_list
    |> Enum.group_by(& &1.source_id)
    |> Enum.each(fn {source_id, slices} ->
      PubSub.broadcast("slicing:#{source_id}", {:new_slices, slices})
    end)
  end
end
