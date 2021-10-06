defmodule MediaWatchWeb.ItemLive do
  use MediaWatchWeb, :live_view
  alias MediaWatch.{Snapshots, Analysis}
  alias MediaWatchWeb.Component.{Item, List, ShowOccurrence}

  @impl true
  def mount(_params = %{"id" => id}, _session, socket) do
    Analysis.subscribe(id)
    item = Analysis.get_analyzed_item(id)

    {:ok,
     socket
     |> assign(item: item, description: item.description, occurrences: item.show.occurrences)}
  end

  @impl true
  def handle_info(desc, socket) when is_struct(desc, MediaWatch.Analysis.Description),
    do: {:noreply, socket |> assign(description: desc)}

  def handle_info(occ, socket) when is_struct(occ, MediaWatch.Analysis.ShowOccurrence) do
    occurrences =
      (socket.assigns.occurrences ++ [occ]) |> Enum.sort_by(& &1.airing_time, {:desc, DateTime})

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

      <%= render_occurrences(assigns) %>
    """

  defp render_occurrences(assigns = %{occurrences: []}),
    do: ~H"<p>Pas d'émission disponible</p>"

  defp render_occurrences(assigns),
    do: ~H"""
      <List.ul let={occ} list={@occurrences} class="occurrence card">
        <ShowOccurrence.as_card occurrence={occ} />
      </List.ul>
    """
end
