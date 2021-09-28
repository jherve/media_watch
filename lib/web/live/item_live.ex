defmodule MediaWatchWeb.ItemLive do
  use MediaWatchWeb, :live_view
  alias MediaWatch.{Snapshots, Analysis}
  alias MediaWatchWeb.Component.{Item, Description, ShowOccurrence}

  @impl true
  def mount(_params = %{"id" => id}, _session, socket) do
    Analysis.subscribe(id)
    item = Analysis.get_analyzed_item(id)

    {:ok,
     socket
     |> assign(item: item, description: item.description, occurrences: item.show.occurrences)}
  end

  @impl true
  def handle_info({:new_description, desc}, socket),
    do: {:noreply, socket |> assign(description: desc)}

  def handle_info({:new_occurrence, occ}, socket) do
    occurrences =
      (socket.assigns.occurrences ++ [occ]) |> Enum.sort_by(& &1.date_start, {:desc, DateTime})

    {:noreply, socket |> assign(occurrences: occurrences)}
  end

  @impl true
  def handle_event("trigger_snapshots", %{}, socket) do
    socket.assigns.item.module |> Snapshots.do_snapshots()
    {:noreply, socket}
  end

  @impl true
  def render(assigns),
    do: ~H"""
      <Item.as_banner item={@item} id="item-banner" />
      <button phx-click="trigger_snapshots">Lancer les snapshots</button>

      <h2>Emissions</h2>

      <ShowOccurrence.list occurrences={@occurrences} />
    """
end
