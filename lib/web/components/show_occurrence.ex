defmodule MediaWatchWeb.Component.ShowOccurrence do
  use Phoenix.Component
  use Phoenix.HTML
  alias MediaWatchWeb.Component.Card

  def link_(assigns),
    do: ~H"""
      <%= if @occurrence.link, do: link("Lien vers l'émission", to: @occurrence.link) %>
    """

  def as_card(assigns),
    do: ~H"""
      <Card.only_text let={block} class="occurrence">
        <%= case block do %>
          <% :header -> %><%= @occurrence.title %>
          <% :content -> %>
            <div class="description"><%= @occurrence.description %></div>
            <.link_ {assigns} />
          <% :footer -> %><%= @occurrence.airing_time |> Timex.to_date %>
        <% end %>
      </Card.only_text>
    """
end
