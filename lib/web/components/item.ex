defmodule MediaWatchWeb.Component.Item do
  use Phoenix.Component
  use Phoenix.HTML
  alias MediaWatchWeb.Component.{Description, Card}

  def title(item), do: item.show.name

  def channels(item), do: item.channels |> Enum.map(& &1.name) |> Enum.join(", ")

  def detail_link(item),
    do: MediaWatchWeb.Router.Helpers.item_path(MediaWatchWeb.Endpoint, :detail, item.id)

  def as_card(assigns),
    do: ~H"""
      <Card.with_image let={block} class="item">
        <%= case block do %>
          <% :header -> %><%= title(@item) %> (<%= channels(@item) %>)
          <% :content -> %><Description.short description={@item.description} />
          <% :image -> %><Description.image description={@item.description} />
          <% _ -> %>
        <% end %>
      </Card.with_image>
    """

  def as_banner(assigns),
    do: ~H"""
      <div id={@id} class="item banner">
        <h1><%= title(@item) %> (<%= channels(@item) %>)</h1>
        <p><Description.short description={@item.description} /></p>
        <Description.image description={@item.description} />
        <Description.link description={@item.description}>Lien vers l'émission</Description.link>
      </div>
    """
end
