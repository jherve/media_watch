defmodule MediaWatch.Analysis.Descriptor do
  use GenServer
  alias MediaWatch.{Analysis, PubSub}
  alias MediaWatch.Parsing.Slice
  alias MediaWatch.Analysis.Description
  @name MediaWatch.Analysis.Descriptor

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: @name)
  end

  @impl true
  def init(_opts) do
    PubSub.subscribe("slicing")
    {:ok, nil}
  end

  @impl true
  def handle_info(slice = %Slice{type: :rss_channel_description}, state) do
    Analysis.make_description(slice) |> publish_results()
    {:noreply, state}
  end

  def handle_info(%Slice{}, state), do: {:noreply, state}

  defp publish_results({:ok, desc = %Description{}}) do
    PubSub.broadcast("description", desc)
    PubSub.broadcast("description:#{desc.id}", {:new_description, desc})
  end
end
