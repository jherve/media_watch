defmodule MediaWatchWeb.ShowOccurrenceIndexLive do
  use MediaWatchWeb, :live_view
  alias MediaWatch.{Catalog, Analysis, DateTime}
  alias MediaWatchWeb.Component.List
  alias MediaWatchWeb.ShowOccurrenceLiveComponent
  alias MediaWatchWeb.ItemDescriptionView
  @timezone DateTime.default_tz()
  @reset_by_person person: nil, person_id: nil
  @reset_by_date start_time: nil, end_time: nil, next_day: nil, previous_day: nil

  @impl true
  def mount(_, _, socket),
    do: {:ok, socket |> assign(css_page_id: "show-occurrence-index", display_admin?: false)}

  @impl true
  def handle_params(_params = %{"date" => date_string}, _, socket) do
    case date_string |> DateTime.parse_date() do
      {:ok, date} ->
        {:noreply, socket |> switch_mode(day: date |> Timex.to_date()) |> set_occurrences()}
    end
  end

  def handle_params(_params = %{"person_id" => person_id}, _, socket) do
    {:noreply, socket |> switch_mode(person_id: person_id) |> set_occurrences()}
  end

  def handle_params(_params, _, socket),
    do: {:noreply, socket |> switch_mode(day: Timex.today()) |> set_occurrences()}

  defp switch_mode(socket, opts = [day: _]),
    do:
      socket
      |> assign(mode: :by_date)
      |> assign(opts)
      |> assign(@reset_by_person)
      |> set_dates()
      |> set_datetimes()
      |> set_dates_url()
      |> set_title

  defp switch_mode(socket, opts = [person_id: person_id]),
    do:
      socket
      |> assign(mode: :by_person)
      |> assign(opts)
      |> assign(@reset_by_date)
      |> assign(person: Catalog.get_person(person_id))
      |> set_title

  @impl true
  def handle_info({:display_admin?, display_admin?}, socket),
    do: {:noreply, socket |> assign(display_admin?: display_admin?)}

  @impl true
  def render(assigns),
    do: ~H"""
      <%= MediaWatchWeb.AdminToggleLiveComponent.as_component(assigns) %>
      <h1><%= @page_title %></h1>
      <%= render_nav_links(assigns) %>

      <List.ul let={occurrence} list={@occurrences} ul_class="show-occurrence">
        <.live_component module={ShowOccurrenceLiveComponent}
                         id={occurrence.id}
                         occurrence={occurrence}
                         image_url={ItemDescriptionView.image_url(occurrence.show.item.description)}
                         display_link_to_item={true}
                         display_link_to_date={true}
                         can_edit_invitations?={@display_admin?}/>
      </List.ul>
    """

  defp render_nav_links(assigns = %{mode: :by_date}),
    do: ~H"""
    <div class="navigation">
      <%= live_patch @previous_day |> DateTime.to_string(), to: @previous_day_link, class: "previous" %>
      <%= live_patch @next_day |> DateTime.to_string(), to: @next_day_link, class: "next" %>
    </div>
    """

  defp render_nav_links(%{mode: :by_person}), do: []

  defp set_dates(socket = %{assigns: %{day: day}}),
    do:
      socket
      |> assign(
        next_day: day |> DateTime.next_day(),
        previous_day: day |> DateTime.previous_day()
      )

  defp set_datetimes(socket) do
    {start_time, end_time} = DateTime.into_day_slot(socket.assigns.day, @timezone)

    socket
    |> assign(start_time: start_time, end_time: end_time)
  end

  defp set_dates_url(socket),
    do:
      socket
      |> assign(
        next_day_link:
          Routes.show_occurrence_index_path(socket, :index, date: "#{socket.assigns.next_day}"),
        previous_day_link:
          Routes.show_occurrence_index_path(socket, :index, date: "#{socket.assigns.previous_day}")
      )

  defp set_occurrences(socket = %{assigns: assigns = %{mode: :by_date}}),
    do:
      socket
      |> assign(occurrences: Analysis.list_show_occurrences(assigns.start_time, assigns.end_time))

  defp set_occurrences(socket = %{assigns: assigns = %{mode: :by_person}}),
    do:
      socket
      |> assign(occurrences: Analysis.list_show_occurrences(person_id: assigns.person_id))

  defp set_title(socket = %{assigns: %{mode: :by_date, day: day}}),
    do:
      socket
      |> assign(page_title: "Émissions diffusées le #{day |> DateTime.to_string()}")

  defp set_title(socket = %{assigns: %{mode: :by_person, person: person}}),
    do:
      socket
      |> assign(page_title: "Liste des apparitions de #{person.label} (#{person.description})")
end
