defmodule MediaWatchWeb.PersonIndexLive do
  use MediaWatchWeb, :live_view
  alias MediaWatch.Catalog
  alias MediaWatchWeb.Component.List
  alias MediaWatchWeb.PersonLiveComponent
  alias MediaWatchWeb.PersonView

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket |> assign(persons: Catalog.list_persons())}
  end

  @impl true
  def render(assigns),
    do: ~H"""
      <h1>Liste des personnes</h1>

      <List.ul let={person} list={@persons} id="person-full-list" class="person">
        <.live_component module={PersonLiveComponent}
                         id={person.id}
                         person={person}
                         wrap_in_link={true}/>
      </List.ul>
    """
end
