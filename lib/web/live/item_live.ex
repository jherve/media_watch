defmodule MediaWatchWeb.ItemLive do
  use MediaWatchWeb, :live_view
  alias MediaWatch.{Snapshots, Analysis}
  alias MediaWatchWeb.Component.{Item, Description}

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
      <h1><Item.title item={@item} /><button phx-click="trigger_snapshots">Lancer les snapshots</button></h1>

      <Description.description description={@description} />

      <h2>Emissions</h2>

      <%= render_occurrences_list(assigns) %>
    """

  defp render_occurrences_list(assigns = %{occurrences: []}),
    do: ~H"<p>Pas d'émission disponible</p>"

  defp render_occurrences_list(assigns),
    do: ~H"""
    <ul>
      <%= for o <- @occurrences do %>
        <li><%= render_occurrence(o) %></li>
      <% end %>
    </ul>
    """

  defp render_occurrence(o),
    do: ~E"""
      <h3><%= o.date_start |> Timex.to_date %> : <%= o.title %></h3>
      <p><%= o.description %></p>
      <p><%= if o.link, do: link("Lien", to: o.link) %></p>
    """
end
