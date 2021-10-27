defmodule MediaWatchWeb.ItemLiveComponent do
  use MediaWatchWeb, :live_component
  alias MediaWatchWeb.Component.Card
  alias MediaWatchWeb.{ItemView, ItemDescriptionView}

  def render(assigns),
    do: ~H"""
      <div>
        <Card.card class="item">
          <:header><%= ItemView.title(@item) %> (<%= ItemView.channels(@item) %>)</:header>
          <:content><%= ItemDescriptionView.description(@item.description) %></:content>
          <:image><%= if url = ItemDescriptionView.image_url(@item.description) do %><img src={url}/><% end %></:image>
        </Card.card>
      </div>
    """
end
