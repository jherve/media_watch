defmodule MediaWatchWeb.FacetIndexLive do
  use MediaWatchWeb, :live_view
  alias MediaWatch.Analysis
  @one_day Timex.Duration.from_days(1)

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket |> assign(facets: [])}
  end

  @impl true
  def handle_params(_params = %{"date" => date_string}, _, socket) do
    with {:ok, date} <- date_string |> Timex.parse("{YYYY}-{0M}-{0D}") do
      date_after = Timex.add(date, @one_day)

      {:noreply,
       socket
       |> set_dates(date)
       |> set_dates_url()
       |> assign(facets: Analysis.get_facets_by_date(date, date_after))}
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
        <%= for f <- @facets do %>
          <li>
              <%= f |> render_occurrence %>
          </li>
        <% end %>
      </ul>
    """

  defp render_occurrence(o) do
    ~E"""
      <h3><%= o.show_occurrence.title %></h3>
      <p><%= o.show_occurrence.description %></p>
      <p><%= link "Lien", to: o.show_occurrence.url %></p>
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
          Routes.facet_index_path(socket, :index, date: "#{socket.assigns.next_day}"),
        previous_day_link:
          Routes.facet_index_path(socket, :index, date: "#{socket.assigns.previous_day}")
      )
end
