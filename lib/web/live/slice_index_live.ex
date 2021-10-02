defmodule MediaWatchWeb.SliceIndexLive do
  use MediaWatchWeb, :live_view
  alias MediaWatch.Analysis
  alias MediaWatchWeb.Component.{Item, ShowOccurrence, List, Card}
  @one_day Timex.Duration.from_days(1)
  @truncated_length 100

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket |> assign(items: [])}
  end

  @impl true
  def handle_params(_params = %{"date" => date_string}, _, socket) do
    case date_string |> Timex.parse("{YYYY}-{0M}-{0D}") do
      {:ok, date} -> {:noreply, socket |> set_dates(date) |> set_dates_url() |> set_items()}
    end
  end

  def handle_params(_params, _, socket),
    do: {:noreply, socket |> set_dates() |> set_dates_url() |> set_items()}

  def handle_event("toggle_truncate", %{"occurrence" => id}, socket) do
    id = String.to_integer(id)

    fun =
      if MapSet.member?(socket.assigns.non_truncated_descriptions, id),
        do: &(&1 |> MapSet.delete(id)),
        else: &(&1 |> MapSet.put(id))

    {:noreply, socket |> update(:non_truncated_descriptions, fun)}
  end

  @impl true
  def render(assigns),
    do: ~H"""
      <h1>Liste des diffusions le <%= @day %></h1>
      <%= live_patch @previous_day, to: @previous_day_link %> / <%= live_patch @next_day, to: @next_day_link %>

      <List.ul let={item} list={@items}>
        <% [occurrence] = item.show.occurrences %>
        <Card.with_image let={block} class="show-occurrence">
          <%= case block do %>
            <% :header -> %><%= occurrence.title %>
            <% :content -> %>
              <h1><Item.detail_link item={item}><Item.title item={item}/></Item.detail_link></h1>
              <p phx-click="toggle_truncate" phx-value-occurrence={occurrence.id}><%= maybe_truncate_description(assigns, occurrence) %></p>
            <% :image -> %><img src={(item.description || %{image: %{}}).image["url"]}>
            <% _ -> %>
          <% end %>
        </Card.with_image>
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
          Routes.slice_index_path(socket, :index, date: "#{socket.assigns.next_day}"),
        previous_day_link:
          Routes.slice_index_path(socket, :index, date: "#{socket.assigns.previous_day}")
      )

  defp set_items(socket = %{assigns: %{day: day, next_day: next_day}}),
    do:
      socket
      |> assign(
        items: Analysis.get_analyzed_item_by_date(day, next_day),
        non_truncated_descriptions: MapSet.new()
      )

  defp maybe_truncate_description(assigns, occurrence) do
    if MapSet.member?(assigns.non_truncated_descriptions, occurrence.id),
      do: ~H"<%= occurrence.description %>",
      else: ~H"<%= occurrence.description |> truncate() %>"
  end

  defp truncate(string, max \\ @truncated_length) do
    length = string |> String.length()
    if length > max, do: "#{string |> String.slice(0..100)}...", else: string
  end
end
