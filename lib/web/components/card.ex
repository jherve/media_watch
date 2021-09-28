defmodule MediaWatchWeb.Component.Card do
  use Phoenix.Component

  def with_image(assigns) do
    assigns = assigns |> assign(:class, "card " <> (assigns |> Map.get(:class, "")))

    ~H"""
      <article class={@class}>
        <h1><%= render_block(@inner_block, :header) %></h1>
        <div class="content"><%= render_block(@inner_block, :content) %></div>
        <%= render_block(@inner_block, :image) %>
        <div class="footer"><%= render_block(@inner_block, :footer) %></div>
      </article>
    """
  end

  def only_text(assigns) do
    assigns = assigns |> assign(:class, "card card-text " <> (assigns |> Map.get(:class, "")))

    ~H"""
      <article class={@class}>
        <h1><%= render_block(@inner_block, :header) %></h1>
        <div class="content"><%= render_block(@inner_block, :content) %></div>
        <div class="footer"><%= render_block(@inner_block, :footer) %></div>
      </article>
    """
  end
end
