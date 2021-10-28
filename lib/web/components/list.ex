defmodule MediaWatchWeb.Component.List do
  use Phoenix.Component

  defguardp has_list(assigns) when is_map_key(assigns, :list) and is_list(assigns.list)

  def ul(assigns) when has_list(assigns) do
    assigns = assigns |> assign_new(:class, fn -> "" end) |> assign_new(:id, fn -> nil end)

    ~H"""
      <ul class={@class} id={@id}>
        <%= for entry <- @list do %>
          <li class={@class}><%= render_slot(@inner_block, entry) %></li>
        <% end %>
      </ul>
    """
  end
end
