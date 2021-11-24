defmodule MediaWatchWeb.Component.List do
  use Phoenix.Component

  defguardp has_list(assigns) when is_map_key(assigns, :list) and is_list(assigns.list)

  def ul(assigns) when has_list(assigns) do
    assigns =
      assigns
      |> assign_new(:ul_class, fn -> "" end)
      |> assign_new(:li_class, fn -> "" end)
      |> assign_new(:id, fn -> nil end)

    ~H"""
      <ul class={@ul_class} id={@id}>
        <%= for entry <- @list do %>
          <li class={@li_class}><%= render_slot(@inner_block, entry) %></li>
        <% end %>
      </ul>
    """
  end
end
