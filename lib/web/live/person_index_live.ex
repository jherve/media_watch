defmodule MediaWatchWeb.PersonIndexLive do
  use MediaWatchWeb, :live_view
  alias MediaWatch.{Catalog, Fuzzy}
  alias MediaWatchWeb.Component.List
  alias MediaWatchWeb.PersonLiveComponent

  @impl true
  def mount(_params, _session, socket) do
    all_persons = Catalog.list_persons()

    {:ok,
     socket
     |> assign(
       page_title: "Personnes apparues dans les émissions",
       css_page_id: "person-index",
       all_persons: all_persons,
       persons_displayed: all_persons,
       search_cs: changeset()
     )}
  end

  @impl true
  def handle_event("change", %{"search" => params}, socket) do
    cs = params |> changeset()

    filter =
      case cs |> extract_value do
        {:error, :no_input} ->
          fn list -> list end

        label ->
          fn list -> list |> Fuzzy.filter(label, & &1.label) end
      end

    {:noreply,
     socket |> assign(changeset: cs, persons_displayed: socket.assigns.all_persons |> filter.())}
  end

  @impl true
  def render(assigns),
    do: ~H"""
      <h1><%= @page_title %></h1>

      <%= render_search_form(assigns) %>

      <%= render_persons(assigns) %>
    """

  defp render_search_form(assigns),
    do: ~H"""
      <.form
        let={f}
        for={@search_cs}
        as="search"
        id="person-search-form"
        phx-change="change">

        <%= label f, :label, "Rechercher une personne" %>
        <%= text_input f, :label %>
      </.form>
    """

  defp render_persons(assigns) do
    assigns =
      assigns
      |> assign(grouped: assigns.persons_displayed |> Enum.group_by(&(&1.label |> String.at(0))))

    ~H"""
      <%= for {first_letter, list} <- @grouped do %>
        <h2><%= first_letter %></h2>
        <List.ul let={person} list={list}>
          <.live_component module={PersonLiveComponent}
                          id={person.id}
                          person={person}
                          wrap_in_link={true}/>
        </List.ul>
      <% end %>
    """
  end

  defp changeset(params \\ %{}) do
    types = %{label: :string}

    {%{}, types}
    |> Ecto.Changeset.cast(params, Map.keys(types))
    |> Ecto.Changeset.validate_required(:label)
  end

  defp extract_value(cs) do
    case cs |> Ecto.Changeset.apply_action(:validate) do
      {:ok, %{label: label}} -> label
      {:error, %{errors: [label: {_, [validation: :required]}]}} -> {:error, :no_input}
    end
  end
end
