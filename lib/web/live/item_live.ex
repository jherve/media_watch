defmodule MediaWatchWeb.ItemLive do
  use MediaWatchWeb, :live_view
  alias MediaWatch.Analysis
  alias MediaWatch.Repo
  alias MediaWatchWeb.Component.List
  alias MediaWatchWeb.ShowOccurrenceLiveComponent
  alias MediaWatchWeb.{ItemView, ItemDescriptionView}

  @impl true
  def mount(_params = %{"id" => id}, _session, socket) do
    Analysis.subscribe(id)
    item = Analysis.get_analyzed_item(id)

    {:ok,
     socket
     |> assign(
       page_title: ItemView.title(item),
       css_page_id: "item-detail",
       item: item,
       description: item.description,
       occurrences: Analysis.list_show_occurrences(item_id: id),
       display_admin?: false
     )}
  end

  @impl true
  def handle_info({:display_admin?, display_admin?}, socket),
    do: {:noreply, socket |> assign(display_admin?: display_admin?)}

  def handle_info(desc, socket) when is_struct(desc, MediaWatch.Analysis.Description),
    do: {:noreply, socket |> assign(description: desc)}

  def handle_info(occ, socket) when is_struct(occ, MediaWatch.Analysis.ShowOccurrence) do
    # TODO: This should most likely be done in the show_occurrence component
    occ = occ |> Repo.preload([:detail, :guests])

    # Occurrence updates are sent using the same message format, hence the need for
    # the call to `Enum.uniq_by/2`. This function only keeps the first value in case
    # of duplicates, so the new occurrence is always prepended to the list of
    # existing ones to ensure that it replaces the out-dated one.
    occurrences =
      ([occ] ++ socket.assigns.occurrences)
      |> Enum.uniq_by(& &1.id)
      |> Enum.sort_by(& &1.airing_time, {:desc, DateTime})

    {:noreply, socket |> assign(occurrences: occurrences)}
  end

  @impl true
  def render(assigns),
    do: ~H"""
      <%= MediaWatchWeb.AdminToggleLiveComponent.as_component(assigns) %>
      <%= as_banner(assigns) %>

      <h2>Emissions</h2>

      <%= render_occurrences(assigns) %>
    """

  defp as_banner(assigns),
    do: ~H"""
      <div id="item-banner" class="item banner">
        <h1><%= @page_title %></h1>
        <span class="channel"><%= ItemView.channels(@item) %></span>
        <span class="schedule"><%= ItemView.schedule(@item) %></span>
        <p><%= ItemDescriptionView.description(@description) %></p>
        <%= if url = ItemDescriptionView.image_url(@description) do %><img src={url}/><% end %>
        <%= if link_ = ItemDescriptionView.link(@description) do %>
          <%= link "Lien vers l'émission", to: link_ %>
        <% else %>
          Pas de lien disponible
        <% end %>
      </div>
    """

  defp render_occurrences(assigns = %{occurrences: []}),
    do: ~H"<p>Pas d'émission disponible</p>"

  defp render_occurrences(assigns),
    do: ~H"""
      <List.ul let={occ} list={@occurrences} ul_class="show-occurrence">
        <.live_component module={ShowOccurrenceLiveComponent}
                         id={occ.id}
                         occurrence={occ}
                         display_link_to_date={true}
                         can_edit_invitations?={@display_admin?} />
      </List.ul>
    """
end
