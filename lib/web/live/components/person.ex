defmodule MediaWatchWeb.PersonLiveComponent do
  use MediaWatchWeb, :live_component
  alias MediaWatchWeb.Component.Card
  alias MediaWatchWeb.{ItemView, ItemDescriptionView}

  def render(assigns),
    do: ~H"""
      <div>
        <%= @person.label %>
      </div>
    """
end
