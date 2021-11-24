defmodule MediaWatchWeb.LayoutView do
  use MediaWatchWeb, :view

  def render_navigation(assigns),
    do: ~H"""
      <nav>
        <ul>
          <%= for {text, url} <- navigation_items(@conn) do %>
            <li><%= live_redirect text, to: url %></li>
          <% end %>
        </ul>
      </nav>
    """

  defp navigation_items(conn),
    do: [
      {"Emissions", Routes.item_index_path(conn, :index)},
      {"Par date", Routes.show_occurrence_index_path(conn, :index)},
      {"Personnes", Routes.person_index_path(conn, :index)}
    ]

  def render_footer(assigns),
    do: ~H"""
      <nav>
        <%= for {text, url} <- footer_items(@conn) do %>
          <span><a href={url}><%= text %></a></span>
        <% end %>
      </nav>
      <span class="version">Version <%= version_string() %></span>
    """

  defp footer_items(conn), do: [{"Nouveautés", Routes.changelog_path(conn, :index)}]
  defp version_string(), do: Application.spec(:media_watch) |> Keyword.get(:vsn)

  def main_css_attributes(), do: [role: "main", class: "container"]

  def flash_css_attributes(level), do: [class: "alert alert-#{level}", role: "alert"]
end
