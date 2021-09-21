defmodule MediaWatchWeb.ItemIndexLive do
  use MediaWatchWeb, :live_view
  alias MediaWatch.{Catalog, Snapshots}
  alias MediaWatchWeb.ItemView

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket |> assign(items: Catalog.list_all())}
  end

  @impl true
  def handle_event("trigger_all_snapshots", %{}, socket) do
    Snapshots.do_all_snapshots()
    {:noreply, socket}
  end

  @impl true
  def render(assigns),
    do: ~L"""
      <h1>Liste des émissions <button phx-click="trigger_all_snapshots">Lancer tous les snapshots</button></h1>

      <ul>
        <%= for i <- @items do %>
          <li>
              <%= link to: MediaWatchWeb.Router.Helpers.item_path(MediaWatchWeb.Endpoint, :detail, i.id) do %>
                <%= ItemView.item_title(i) %>
              <% end %>
          </li>
        <% end %>
      </ul>
    """
end
