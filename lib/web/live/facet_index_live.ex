defmodule MediaWatchWeb.SliceIndexLive do
  use MediaWatchWeb, :live_view
  alias MediaWatch.Parsing
  @one_day Timex.Duration.from_days(1)

  @impl true
  def mount(_params, _session, socket) do
    raise "This feature is unavailable since the switch to 'slices' / rss_entry / ..."
    {:ok, socket |> assign(slices: [])}
  end

  @impl true
  def handle_params(_params = %{"date" => date_string}, _, socket) do
    with {:ok, date} <- date_string |> Timex.parse("{YYYY}-{0M}-{0D}") do
      date_after = Timex.add(date, @one_day)

      {:noreply,
       socket
       |> set_dates(date)
       |> set_dates_url()
       |> assign(slices: Parsing.get_slices_by_date(date, date_after))}
    end
  end

  def handle_params(_params, _, socket) do
    {:noreply, socket |> set_dates() |> set_dates_url()}
  end

  @impl true
  def render(assigns),
    do: ~L"""
      <h1>Liste des diffusions le <%= @day %></h1>
      <%= live_patch @previous_day, to: @previous_day_link %> / <%= live_patch @next_day, to: @next_day_link %>

      <ul>
        <%= for s <- @slices do %>
          <li>
              <%= s |> render_occurrence %>
          </li>
        <% end %>
      </ul>
    """

  defp render_occurrence(o) do
    ~E"""
      <h3><%= o.rss_entry.title %></h3>
      <p><%= o.rss_entry.description %></p>
      <p><%= link "Lien", to: o.rss_entry.url %></p>
    """
  end

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
end
