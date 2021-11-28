defmodule MediaWatchWeb.Component.Icon do
  use Phoenix.Component

  def icon(assigns) do
    assigns = assigns |> assign_new(:class, fn -> "" end)

    ~H"""
      <i class={"icon-#{@icon} #{@class}"} title={@title}></i>
    """
  end
end
