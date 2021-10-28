defmodule MediaWatchWeb.ShowOccurrenceIndexLive do
  use MediaWatchWeb, :live_view
  alias Timex.Timezone
  alias MediaWatch.Analysis
  alias MediaWatchWeb.Component.List
  alias MediaWatchWeb.ShowOccurrenceLiveComponent
  alias MediaWatchWeb.ItemDescriptionView
  @one_day Timex.Duration.from_days(1)
  @timezone "Europe/Paris" |> Timezone.get()

  @impl true
  def handle_params(_params = %{"date" => date_string}, _, socket) do
    case date_string |> Timex.parse("{YYYY}-{0M}-{0D}") do
      {:ok, date} ->
        {:noreply,
         socket
         |> assign(day: date |> Timex.to_date())
         |> set_dates()
         |> set_datetimes()
         |> set_dates_url()
         |> set_occurrences()}
    end
  end

  def handle_params(_params, _, socket),
    do:
      {:noreply,
       socket
       |> assign(day: Timex.today())
       |> set_dates()
       |> set_datetimes()
       |> set_dates_url()
       |> set_occurrences()}

  @impl true
  def render(assigns),
    do: ~H"""
      <h1>Liste des diffusions le <%= @day %></h1>
      <%= live_patch @previous_day, to: @previous_day_link %> / <%= live_patch @next_day, to: @next_day_link %>

      <List.ul let={occurrence} list={@occurrences} class="card occurrence">
        <.live_component module={ShowOccurrenceLiveComponent}
                         id={occurrence.id}
                         occurrence={occurrence}
                         image_url={ItemDescriptionView.image_url(occurrence.show.item.description)}
                         display_link_to_item={true}/>
      </List.ul>
    """

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

  defp set_occurrences(socket = %{assigns: assigns}),
    do:
      socket
      |> assign(occurrences: Analysis.list_show_occurrences(assigns.start_time, assigns.end_time))
end
