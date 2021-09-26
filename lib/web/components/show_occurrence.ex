defmodule MediaWatchWeb.Component.ShowOccurrence do
  use Phoenix.Component
  use Phoenix.HTML

  def list(assigns = %{occurrences: []}),
    do: ~H"<p>Pas d'émission disponible</p>"

  def list(assigns),
    do: ~H"""
    <ul>
      <%= for o <- @occurrences do %>
        <li><.occurrence occurrence={o} /></li>
      <% end %>
    </ul>
    """

  def occurrence(assigns),
    do: ~H"""
      <h3><%= @occurrence.date_start |> Timex.to_date %> : <%= @occurrence.title %></h3>
      <p><%= @occurrence.description %></p>
      <p><.link_ {assigns} /></p>
    """

  def link_(assigns),
    do: ~H"""
      <%= if @occurrence.link, do: link("Lien", to: @occurrence.link) %>
    """
end
