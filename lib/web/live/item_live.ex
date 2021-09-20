defmodule MediaWatchWeb.ItemLive do
  use MediaWatchWeb, :live_view
  alias MediaWatch.{Snapshots, Catalog, Analysis}
  alias MediaWatchWeb.ItemView

  @impl true
  def mount(_params = %{"id" => id}, _session, socket) do
    Analysis.subscribe(id)

    {:ok, socket |> assign(item: Catalog.get(id))}
  end

  @impl true
  def handle_params(_params, _, socket) do
    {description, occurrences} = Analysis.get_all_slices(socket.assigns.item.id) |> group_slices

    {:noreply, socket |> assign(description: description, occurrences: occurrences)}
  end

  @impl true
  def handle_info({:new_slices, slices}, socket) when is_list(slices),
    do:
      {:noreply,
       socket |> push_patch(to: Routes.item_path(socket, :detail, socket.assigns.item.id))}

  @impl true
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
      <dd><%= link @description.rss_channel_description.link, to: @description.rss_channel_description.link %></dd>
      <dt>Description</dt>
      <dd><%= @description.rss_channel_description.description %></dd>
      <dt>Image</dt>
      <dd><img src="<%= @description.rss_channel_description.image["url"] %>"/></dd>
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
      <h3><%= o.rss_entry.pub_date |> Timex.to_date %> : <%= o.rss_entry.title %></h3>
      <p><%= o.rss_entry.description %></p>
      <p><%= link "Lien", to: o.rss_entry.link %></p>
    """

  defp group_slices(slices) do
    # TODO : This case prevents loading a description when there is no rss_entry yet
    case slices
         |> Enum.group_by(&{not is_nil(&1.rss_entry), not is_nil(&1.rss_channel_description)}) do
      %{{false, true} => [description], {true, false} => occurrences} ->
        {description, occurrences}

      %{} ->
        {:error, :error}
    end
  end
end
