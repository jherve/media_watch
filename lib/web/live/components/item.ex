defmodule MediaWatchWeb.ItemLiveComponent do
  use MediaWatchWeb, :live_component
  alias MediaWatchWeb.{ItemView, ItemDescriptionView}

  @impl true
  def mount(socket), do: {:ok, socket |> assign(display_channel: true)}

  @impl true
  def render(assigns),
    do: ~H"""
      <div class="item">
        <%= live_redirect to: ItemView.detail_link(@item.id) do %>
          <%= if url = ItemDescriptionView.image_url(@item.description) do %>
            <img src={url} alt={title(assigns)}/>
          <% else %>
            <h2><%= title(assigns) %>
          <% end %>
        <% end %>
      </div>
    """

  defp title(assigns),
    do: ~H"""
    <%= ItemView.title(@item) %><%= if @display_channel do %>(<%= ItemView.channels(@item) %>)<% end %>
    """
end
