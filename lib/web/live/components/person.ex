defmodule MediaWatchWeb.PersonLiveComponent do
  use MediaWatchWeb, :live_component
  alias MediaWatchWeb.PersonView

  @impl true
  def update(assigns, socket),
    do: {:ok, socket |> assign(assigns) |> assign_new(:wrap_in_link, fn -> false end)}

  def render(assigns = %{wrap_in_link: true}),
    do: ~H"""
      <div class="person">
        <%= live_redirect to: PersonView.link_occurrences(@person.id) do %><%= render_person(assigns) %><% end %>
      </div>
    """

  def render(assigns),
    do: ~H"""
      <div class="person">
        <%= render_person(assigns) %>
      </div>
    """

  defp render_person(assigns), do: ~H"<%= @person.label %>"
end
