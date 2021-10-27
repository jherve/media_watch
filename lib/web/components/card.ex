defmodule MediaWatchWeb.Component.Card do
  use Phoenix.Component

  def card(assigns) do
    has_image? = assigns |> Map.has_key?(:image)
    base_class = unless has_image?, do: "card card-text ", else: "card "

    assigns =
      assigns
      |> assign(:has_image?, has_image?)
      |> assign(:class, base_class <> (assigns |> Map.get(:class, "")))
      |> assign_new(:footer, fn -> [] end)
      |> assign_new(:image, fn -> [] end)

    ~H"""
      <article class={@class}>
        <h1><%= render_slot(@header) %></h1>
        <div class="content"><%= render_slot(@content) %></div>
        <%= if @has_image? do %><%= render_slot(@image) %><% end %>
        <div class="footer"><%= render_slot(@footer) %></div>
      </article>
    """
  end
end
