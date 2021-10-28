defmodule MediaWatchWeb.ShowOccurrenceIndexLive do
  use MediaWatchWeb, :live_view
  alias Timex.Timezone
  alias MediaWatch.{Catalog, Analysis, DateTime}
  alias MediaWatchWeb.Component.List
  alias MediaWatchWeb.ShowOccurrenceLiveComponent
  alias MediaWatchWeb.ItemDescriptionView
  @one_day Timex.Duration.from_days(1)
  @timezone "Europe/Paris"
  @reset_by_person person: nil, person_id: nil
  @reset_by_date start_time: nil, end_time: nil, next_day: nil, previous_day: nil

  @impl true
  def handle_params(_params = %{"date" => date_string}, _, socket) do
    case date_string |> Timex.parse("{YYYY}-{0M}-{0D}") do
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

  defp switch_mode(socket, opts = [person_id: person_id]),
    do:
      socket
      |> assign(mode: :by_person)
      |> assign(opts)
      |> assign(@reset_by_date)
      |> assign(person: Catalog.get_person(person_id))

  @impl true
  def render(assigns),
    do: ~H"""
      <h1><%= render_title(assigns) %></h1>
      <%= render_nav_links(assigns) %>

      <List.ul let={occurrence} list={@occurrences} class="card occurrence">
        <.live_component module={ShowOccurrenceLiveComponent}
                         id={occurrence.id}
                         occurrence={occurrence}
                         image_url={ItemDescriptionView.image_url(occurrence.show.item.description)}
                         display_link_to_item={true}
                         display_link_to_date={true}/>
      </List.ul>
    """

  defp render_title(assigns = %{mode: :by_date}),
    do: ~H[Liste des diffusions le <%= @day |> DateTime.to_string() %>]

  defp render_title(assigns = %{mode: :by_person}),
    do: ~H|Liste des apparitions de <%= @person.label %> (<%= @person.description %>)|

  defp render_nav_links(assigns = %{mode: :by_date}),
    do:
      ~H[<%= live_patch @previous_day |> DateTime.to_string(), to: @previous_day_link %> / <%= live_patch @next_day |> DateTime.to_string(), to: @next_day_link %>]

  defp render_nav_links(assigns = %{mode: :by_person}), do: []

  defp set_dates(socket = %{assigns: %{day: day}}),
    do:
      socket
      |> assign(
        next_day: day |> Timex.add(@one_day) |> Timex.to_date(),
        previous_day: day |> Timex.subtract(@one_day) |> Timex.to_date()
      )

  defp set_datetimes(socket) do
    day_as_dt = socket.assigns.day |> Timex.to_datetime(@timezone)

    socket
    |> assign(
      start_time: day_as_dt |> Timezone.beginning_of_day(),
      end_time: day_as_dt |> Timezone.end_of_day()
    )
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
end
