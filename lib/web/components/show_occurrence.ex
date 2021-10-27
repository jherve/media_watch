defmodule MediaWatchWeb.Component.ShowOccurrence do
  use Phoenix.Component
  use Phoenix.HTML
  alias MediaWatchWeb.Component.Card

  def link_(assigns),
    do: ~H"""
      <%= if link_ = @occurrence.detail.link, do: link("Lien vers l'émission", to: link_) %>
    """

  def as_card(assigns),
    do: ~H"""
      <Card.card class="occurrence">
        <:header><%= @occurrence.detail.title %></:header>

        <:content>
          <div class="description"><%= @occurrence.detail.description %></div>
          <.link_ {assigns} />
        </:content>

        <:footer><%= @occurrence.airing_time |> Timex.to_date %></:footer>
      </Card.card>
    """
end
