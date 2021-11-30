defmodule MediaWatchWeb.HomeLive do
  use MediaWatchWeb, :live_view
  alias MediaWatch.{Analysis, DateTime}
  alias MediaWatchWeb.{PersonLiveComponent, ShowOccurrenceLiveComponent, ItemDescriptionView}

  @impl true
  def mount(_params, _session, socket) do
    {current_month_start, _} = current_month_slot = DateTime.current_month_slot()
    {last_month_start, _} = last_month_slot = DateTime.last_month_slot()

    current_month_name =
      current_month_start |> MediaWatch.Cldr.Date.to_string!(format: "LLLL", locale: "fr")

    last_month_name =
      last_month_start |> MediaWatch.Cldr.Date.to_string!(format: "LLLL", locale: "fr")

    {:ok,
     socket
     |> assign(
       page_title: "Page d'accueil",
       css_page_id: "home",
       latest_show_occurrences: Analysis.list_show_occurrences(latest: 5),
       current_week_top:
         DateTime.current_week_slot() |> Analysis.list_persons_by_invitations_count(),
       last_week_top: DateTime.past_week_slot() |> Analysis.list_persons_by_invitations_count(),
       current_month_top:
         DateTime.current_month_slot() |> Analysis.list_persons_by_invitations_count(),
       last_month_top: DateTime.last_month_slot() |> Analysis.list_persons_by_invitations_count(),
       current_month_name: current_month_name,
       last_month_name: last_month_name
     )}
  end

  @impl true
  def render(assigns),
    do: ~H"""
      <h1>Bienvenue !</h1>

      <p>Qui est passé à la TV/radio aujourd'hui ? La <%= live_redirect to: Routes.show_occurrence_index_path(@socket, :index) do %>réponse ici<% end %></p>
      <p>Vous voulez chercher une personne en particulier ? C'est <%= live_redirect to: Routes.person_index_path(@socket, :index) do %>ici<% end %></p>
      <p>Vous pouvez aussi consulter la <%= live_redirect to: Routes.item_index_path(@socket, :index) do %>liste de toutes les émissions suivies<% end %></p>

      <div id="lists-grid">
        <div id="latest-shows">
          <h2>Les dernières émissions</h2>
          <%= render_latest_shows(assigns) %>
        </div>

        <div id="week-top">
          <h2>Les plus invités cette semaine</h2>
          <%= render_top(assigns, :current_week_top) %>
        </div>

        <div id="last-week-top">
          <h2>Les plus invités la semaine dernière</h2>
          <%= render_top(assigns, :last_week_top) %>
        </div>

        <div id="month-top">
          <h2>Les plus invités en <%= @current_month_name %></h2>
          <%= render_top(assigns, :current_month_top) %>
        </div>

        <div id="last-month-top">
          <h2>Les plus invités en <%= @last_month_name %></h2>
          <%= render_top(assigns, :last_month_top) %>
        </div>
      </div>
    """

  defp render_latest_shows(assigns),
    do: ~H"""
    <ul class="show-occurrence">
      <%= for occurrence <- @latest_show_occurrences do %>
        <li>
          <.live_component module={ShowOccurrenceLiveComponent}
                        id={occurrence.id}
                        occurrence={occurrence}
                        image_url={ItemDescriptionView.image_url(occurrence.show.item.description)}
                        display_link_to_item={true} />
        </li>
      <% end %>
    </ul>
    """

  defp render_top(assigns, top_name),
    do: ~H"""
    <ol class="persons-top">
        <%= for %{person: person, count: count} <- assigns[top_name] do %>
          <li>
            <.live_component module={PersonLiveComponent}
                            id={{top_name, person.id}}
                            person={person}
                            wrap_in_link={true} />
            <span class="count"><%= count %></span>
          </li>
        <% end %>
    </ol>
    """
end
