defmodule MediaWatch.Analysis.OccurrenceFormatter do
  use GenServer
  alias MediaWatch.{Analysis, PubSub}
  alias MediaWatch.Parsing.Slice
  alias MediaWatch.Analysis.ShowOccurrence
  @name MediaWatch.Analysis.OccurrenceFormatter

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: @name)
  end

  @impl true
  def init(_opts) do
    PubSub.subscribe("slicing")
    {:ok, nil}
  end

  @impl true
  def handle_info(slice = %Slice{type: :rss_entry}, state) do
    Analysis.make_show_occurrence(slice) |> publish_results()
    {:noreply, state}
  end

  def handle_info(%Slice{}, state), do: {:noreply, state}

  defp publish_results({:ok, occ = %ShowOccurrence{}}) do
    PubSub.broadcast("occurrence_formatting", occ)
    PubSub.broadcast("occurrence_formatting:#{occ.show_id}", {:new_occurrence, occ})
  end
end
