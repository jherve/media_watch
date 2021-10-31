defmodule MediaWatchWeb.ShowOccurrenceLiveComponent do
  use MediaWatchWeb, :live_component
  alias MediaWatch.DateTime
  alias MediaWatchWeb.Component.{List, Card}
  alias MediaWatchWeb.{ItemView, ShowOccurrenceView}
  alias MediaWatchWeb.PersonLiveComponent
  @truncated_length 100

  @impl true
  def mount(socket),
    do: {:ok, socket |> assign(truncate_description: true)}

  @impl true
  def update(assigns = %{occurrence: occ = %{detail: detail}}, socket) do
    airing_day = occ.airing_time |> Timex.to_date()

    {:ok,
     socket
     |> assign(assigns)
     |> assign(
       # In some rare cases the `detail` may be nil because it could not be interpreted correctly
       title:
         if(detail, do: detail.title, else: "Émission du #{airing_day |> DateTime.to_string()}"),
       description: if(detail, do: detail.description),
       guests: occ.guests,
       external_link_to_occurrence: if(detail, do: detail.link),
       link_to_item: ItemView.detail_link(occ.show_id),
       airing_time: occ.airing_time,
       airing_day: airing_day
     )
     |> assign_new(:image_url, fn -> nil end)
     |> assign_new(:display_link_to_item, fn -> false end)
     |> assign_new(:display_link_to_date, fn -> false end)}
  end

  @impl true
  def handle_event("toggle_truncate", _, socket),
    do: {:noreply, socket |> update(:truncate_description, &(not &1))}

  @impl true
  def render(assigns),
    do: ~H"""
      <div>
        <Card.card class="occurrence">
          <:header><%= @title %></:header>

          <:content>
            <%= render_guests(assigns) %>
            <p phx-click="toggle_truncate" phx-target={@myself}><%= render_description(assigns) %></p>
            <%= if @display_link_to_item, do: live_redirect("Toutes les émissions", to: @link_to_item) %>
            <%= if @external_link_to_occurrence, do: link("Lien vers l'émission", to: @external_link_to_occurrence) %>
          </:content>

          <:image><%= if @image_url do %><img src={@image_url}><% end %></:image>

          <:footer><%= render_airing_time(assigns) %></:footer>
        </Card.card>
      </div>
    """

  defp render_guests(assigns = %{guests: []}),
    do: ~H|<div class="guests">Pas d'invités detectés</div>|

  defp render_guests(assigns),
    do: ~H"""
    <List.ul let={guest} list={@guests} class="guests">
      <.live_component module={PersonLiveComponent} id={{@occurrence.id, guest.id}} person={guest} wrap_in_link={true} />
    </List.ul>
    """

  defp render_description(assigns = %{description: nil}), do: ~H"Pas de description disponible"

  defp render_description(assigns = %{truncate_description: true}),
    do: ~H"<%= truncate(@description) %>"

  defp render_description(assigns = %{truncate_description: false}), do: ~H"<%= @description %>"

  defp render_airing_time(assigns = %{display_link_to_date: true}),
    do:
      ~H[<%= live_redirect @airing_day |> DateTime.to_string(), to: ShowOccurrenceView.link_by_date(@airing_day) %>]

  defp render_airing_time(assigns), do: ~H[<%= @airing_day |> DateTime.to_string() %>]

  defp truncate(string, max \\ @truncated_length) do
    length = string |> String.length()
    if length > max, do: "#{string |> String.slice(0..max)}...", else: string
  end
end
