defmodule MediaWatchWeb.Component.Item do
  use Phoenix.Component
  use Phoenix.HTML
  alias MediaWatchWeb.Component.{Description, Card, List}

  def list(assigns),
    do: ~H"""
      <List.ul let={item} list={@items} class="item card">
        <.detail_link item={item}>
          <.as_card item={item} />
        </.detail_link>
      </List.ul>
    """

  def title(assigns),
    do: ~H"""
      <%= @item.show.name %> (<%= @item.channels |> Enum.map(& &1.name) |> Enum.join(", ") %>)
    """

  def clickable_link(assigns),
    do: ~H"""
      <.detail_link item={@item}>
        <h1><.title item={@item} /></h1>
      </.detail_link>
    """

  def detail_link(assigns),
    do: ~H"""
      <%= link to: MediaWatchWeb.Router.Helpers.item_path(MediaWatchWeb.Endpoint, :detail, @item.id) do %>
        <%= render_block(@inner_block) %>
      <% end %>
    """

  def external_link(assigns),
    do: ~H"""
      <%= link to: MediaWatchWeb.Router.Helpers.item_path(MediaWatchWeb.Endpoint, :detail, @item.id) do %>
        <%= render_block(@inner_block) %>
      <% end %>
    """

  def as_card(assigns),
    do: ~H"""
      <Card.with_image let={block} class="item">
        <%= case block do %>
          <% :header -> %><.title item={@item} />
          <% :content -> %><Description.short description={@item.description} />
          <% :image -> %><Description.image description={@item.description} />
          <% _ -> %>
        <% end %>
      </Card.with_image>
    """

  def as_banner(assigns),
    do: ~H"""
      <div id={@id} class="item banner">
        <h1><.title item={@item} /></h1>
        <p><Description.short description={@item.description} /></p>
        <Description.image description={@item.description} />
        <Description.link description={@item.description}>Lien vers l'émission</Description.link>
      </div>
    """
end
