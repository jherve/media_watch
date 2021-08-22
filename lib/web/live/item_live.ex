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

      <dl>
        <dt>URL</dt>
        <dd><%= link @description.description.url, to: @description.description.url %></dd>
        <dt>Description</dt>
        <dd><%= @description.description.description %></dd>
        <dt>Image</dt>
        <dd><img src="<%= @description.description.image %>"/></dd>
      </dl>
    """

  defp group_facets(facets) do
    %{{false, true} => [description], {true, false} => occurrences} =
      facets
      |> Enum.group_by(&{not is_nil(&1.show_occurrence), not is_nil(&1.description)})

    {description, occurrences}
  end
end
