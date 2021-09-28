defmodule MediaWatchWeb.Component.ShowOccurrence do
  use Phoenix.Component
  use Phoenix.HTML
  alias MediaWatchWeb.Component.{List, Card}

  def list(assigns = %{occurrences: []}),
    do: ~H"<p>Pas d'émission disponible</p>"

  def list(assigns),
    do: ~H"""
      <List.ul let={occ} list={@occurrences} class="occurrence card"><.as_card occurrence={occ} /></List.ul>
    """

  def occurrence(assigns),
    do: ~H"""
      <h3><%= @occurrence.date_start |> Timex.to_date %> : <%= @occurrence.title %></h3>
      <p><%= @occurrence.description %></p>
      <p><.link_ {assigns} /></p>
    """

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
          <% :footer -> %><%= @occurrence.date_start |> Timex.to_date %>
        <% end %>
      </Card.only_text>
    """
end
