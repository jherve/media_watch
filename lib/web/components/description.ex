defmodule MediaWatchWeb.Component.Description do
  use Phoenix.Component
  use Phoenix.HTML

  def description(assigns = %{description: nil}),
    do: ~H"<dl>Pas de description disponible</dl>"

  def description(assigns),
    do: ~H"""
    <dl>
      <dt>URL</dt>
      <dd><%= link @description.link, to: @description.link %></dd>
      <dt>Description</dt>
      <dd><%= @description.description %></dd>
      <dt>Image</dt>
      <dd><img src={@description.image["url"]}/></dd>
    </dl>
    """
end
