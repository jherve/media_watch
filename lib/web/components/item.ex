defmodule MediaWatchWeb.Component.Item do
  use Phoenix.Component
  use Phoenix.HTML

  def title(assigns),
    do: ~H"""
      <%= @item.show.name %> (<%= @item.channels |> Enum.map(& &1.name) |> Enum.join(", ") %>)
    """

  def clickable_link(assigns),
    do: ~H"""
      <%= link to: MediaWatchWeb.Router.Helpers.item_path(MediaWatchWeb.Endpoint, :detail, @item.id) do %>
        <.title item={@item} />
      <% end %>
    """
end
