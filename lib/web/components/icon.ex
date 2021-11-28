defmodule MediaWatchWeb.Component.Icon do
  use Phoenix.Component

  def icon(assigns) do
    ~H"""
      <i class={"icon-#{@icon}"} title={@title}></i>
    """
  end
end
