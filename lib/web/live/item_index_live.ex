defmodule MediaWatchWeb.ItemIndexLive do
  use MediaWatchWeb, :live_view
  alias MediaWatch.{Analysis, Snapshots}
  alias MediaWatchWeb.Component.{List, Item}

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket |> assign(items: Analysis.get_all_analyzed_items())}
  end

  @impl true
  def handle_event("trigger_all_snapshots", %{}, socket) do
    Snapshots.do_all_snapshots()
    {:noreply, socket}
  end

  @impl true
  def render(assigns),
    do: ~H"""
      <h1>Liste des émissions <button phx-click="trigger_all_snapshots">Lancer tous les snapshots</button></h1>

      <List.ul let={item} list={@items} class="item card">
        <%= link to: Item.detail_link(item) do %>
          <Item.as_card item={item} />
        <% end %>
      </List.ul>
    """
end
