defmodule MediaWatchWeb.ShowOccurrenceIndexLive do
  use MediaWatchWeb, :live_view
  alias MediaWatch.Analysis
  alias MediaWatchWeb.Component.List
  alias MediaWatchWeb.ShowOccurrenceLiveComponent
  alias MediaWatchWeb.ItemDescriptionView
  @one_day Timex.Duration.from_days(1)

  @impl true
  def handle_params(_params = %{"date" => date_string}, _, socket) do
    case date_string |> Timex.parse("{YYYY}-{0M}-{0D}") do
      {:ok, date} -> {:noreply, socket |> set_dates(date) |> set_dates_url() |> set_occurrences()}
    end
  end

  def handle_params(_params, _, socket),
    do: {:noreply, socket |> set_dates() |> set_dates_url() |> set_occurrences()}

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

  defp set_dates(socket, date \\ Timex.today()),
    do:
      socket
      |> assign(
        day: date |> Timex.to_date(),
        next_day: date |> Timex.add(@one_day) |> Timex.to_date(),
        previous_day: date |> Timex.subtract(@one_day) |> Timex.to_date()
      )

  defp set_dates_url(socket),
    do:
      socket
      |> assign(
        next_day_link:
          Routes.show_occurrence_index_path(socket, :index, date: "#{socket.assigns.next_day}"),
        previous_day_link:
          Routes.show_occurrence_index_path(socket, :index, date: "#{socket.assigns.previous_day}")
      )

  defp set_occurrences(socket = %{assigns: %{day: day, next_day: next_day}}),
    do:
      socket
      |> assign(occurrences: Analysis.list_show_occurrences(day, next_day))
end
