defmodule MediaWatchWeb.Component.Description do
  use Phoenix.Component
  use Phoenix.HTML

  defguardp has_description(assigns) when is_map_key(assigns, :description)

  defguardp has_not_nil_description(assigns)
            when has_description(assigns) and not is_nil(assigns.description) and
                   not is_struct(assigns.description, Ecto.Association.NotLoaded)

  def short(assigns) when has_not_nil_description(assigns),
    do: ~H"<%= @description.description %>"

  def short(assigns) when has_description(assigns), do: ~H"<dl>Pas de description disponible</dl>"

  def image(assigns) when has_not_nil_description(assigns),
    do: ~H|<img src={@description.image["url"]}/>|

  def image(assigns) when has_description(assigns), do: ~H|<img src="#"/>|

  def link(assigns) when has_not_nil_description(assigns),
    do: ~H"""
      <%= link to: @description.link do %><%= render_block(@inner_block) %><% end %>
    """

  def link(assigns) when has_description(assigns), do: ~H|Pas de lien disponible|
end
