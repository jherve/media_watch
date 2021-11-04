defmodule MediaWatchWeb.ItemLiveComponent do
  use MediaWatchWeb, :live_component
  alias MediaWatchWeb.Component.Card
  alias MediaWatchWeb.{ItemView, ItemDescriptionView}

  @impl true
  def mount(socket), do: {:ok, socket |> assign(display_channel: true)}

  @impl true
  def render(assigns),
    do: ~H"""
      <div>
        <Card.card class="item">
          <:header><%= ItemView.title(@item) %><%= if @display_channel do %>(<%= ItemView.channels(@item) %>)<% end %></:header>
          <:image><%= if url = ItemDescriptionView.image_url(@item.description) do %><img src={url}/><% end %></:image>
        </Card.card>
      </div>
    """
end
