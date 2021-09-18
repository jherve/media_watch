defmodule MediaWatchWeb.ItemLive do
  use MediaWatchWeb, :live_view
  alias MediaWatch.{Snapshots, Catalog, Analysis}
  alias MediaWatchWeb.ItemView

  @impl true
  def mount(_params = %{"id" => id}, _session, socket) do
    Analysis.subscribe(id)

    {:ok, socket |> assign(item: Catalog.get(id))}
  end

  def handle_params(params = %{"id" => id}, _, socket) do
    {description, occurrences} = Analysis.get_all_facets(socket.assigns.item.id) |> group_facets

    {:noreply, socket |> assign(description: description, occurrences: occurrences)}
  end

  def handle_info({:new_facets, facets}, socket) when is_list(facets),
    do:
      {:noreply,
       socket |> push_patch(to: Routes.item_path(socket, :detail, socket.assigns.item.id))}

  def handle_event("trigger_snapshots", %{}, socket) do
    socket.assigns.item.id |> Snapshots.do_snapshots()
    {:noreply, socket}
  end

  @impl true
  def render(assigns),
    do: ~L"""
      <h1><%= ItemView.item_title(@item) %><button phx-click="trigger_snapshots">Lancer les snapshots</button></h1>

      <%= render_description(assigns) %>

      <h2>Emissions</h2>

      <%= render_occurrences_list(assigns) %>
    """

  defp render_description(assigns = %{description: :error}),
    do: ~L"<dl>Pas de description disponible</dl>"

  defp render_description(assigns),
    do: ~L"""
    <dl>
      <dt>URL</dt>
      <dd><%= link @description.description.url, to: @description.description.url %></dd>
      <dt>Description</dt>
      <dd><%= @description.description.description %></dd>
      <dt>Image</dt>
      <dd><img src="<%= @description.description.image %>"/></dd>
    </dl>
    """

  defp render_occurrences_list(assigns = %{occurrences: :error}),
    do: ~L"<p>Pas d'émission disponible</p>"

  defp render_occurrences_list(assigns),
    do: ~L"""
    <ul>
      <%= for o <- @occurrences do %>
        <li><%= render_occurrence(o) %></li>
      <% end %>
    </ul>
    """

  defp render_occurrence(o),
    do: ~E"""
      <h3><%= o.date_start |> Timex.to_date %> : <%= o.show_occurrence.title %></h3>
      <p><%= o.show_occurrence.description %></p>
      <p><%= link "Lien", to: o.show_occurrence.url %></p>
    """

  defp group_facets(facets) do
    case facets
         |> Enum.group_by(&{not is_nil(&1.show_occurrence), not is_nil(&1.description)}) do
      %{{false, true} => [description], {true, false} => occurrences} ->
        {description, occurrences}

      %{} ->
        {:error, :error}
    end
  end
end
