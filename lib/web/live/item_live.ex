defmodule MediaWatchWeb.ItemLive do
  use MediaWatchWeb, :live_view
  alias MediaWatch.{Catalog, Analysis}

  @impl true
  def mount(_params = %{"id" => id}, _session, socket) do
    {description, occurrences} = Analysis.get_all_facets(id) |> group_facets

    {:ok,
     socket
     |> assign(
       item: Catalog.get(id),
       description: description,
       occurrences: occurrences
     )}
  end

  @impl true
  def render(assigns),
    do: ~L"""
      <h1><%= @item.show.name %></h1>

      <%= render_description(assigns) %>

      <h2>Emissions</h2>

      <%= render_occurrences_list(assigns) %>
    """

  defp render_description(assigns = %{description: :error}),
    do: ~L"<dl>Pas de description disponible</dl>"

  defp render_description(assigns),
    do: ~L"""
    <dl>
      <dt>URL</dt>
      <dd><%= link @description.description.url, to: @description.description.url %></dd>
      <dt>Description</dt>
      <dd><%= @description.description.description %></dd>
      <dt>Image</dt>
      <dd><img src="<%= @description.description.image %>"/></dd>
    </dl>
    """

  defp render_occurrences_list(assigns = %{occurrences: :error}),
    do: ~L"<p>Pas d'émission disponible</p>"

  defp render_occurrences_list(assigns),
    do: ~L"""
    <ul>
      <%= for o <- @occurrences do %>
        <li><%= render_occurrence(o) %></li>
      <% end %>
    </ul>
    """

  defp render_occurrence(o),
    do: ~E"""
      <h3><%= o.date_start |> Timex.to_date %> : <%= o.show_occurrence.title %></h3>
      <p><%= o.show_occurrence.description %></p>
      <p><%= link "Lien", to: o.show_occurrence.url %></p>
    """

  defp group_facets(facets) do
    case facets
         |> Enum.group_by(&{not is_nil(&1.show_occurrence), not is_nil(&1.description)}) do
      %{{false, true} => [description], {true, false} => occurrences} ->
        {description, occurrences}

      %{} ->
        {:error, :error}
    end
  end
end