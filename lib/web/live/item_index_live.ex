defmodule MediaWatchWeb.ItemIndexLive do
  use MediaWatchWeb, :live_view
  alias MediaWatch.Catalog

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket |> assign(items: Catalog.list_all())}
  end

  def render(assigns),
    do: ~L"""
      <h1>Liste des émissions</h1>

      <ul>
        <%= for i <- @items do %>
          <li> <%= i.show.name %></li>
        <% end %>
      </ul>
    """
end
