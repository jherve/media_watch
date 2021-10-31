defmodule MediaWatchWeb.Component.Card do
  use Phoenix.Component

  def card(assigns) do
    has_image? = assigns |> Map.has_key?(:image)
    has_content? = assigns |> Map.has_key?(:content)

    base_class =
      cond do
        has_image? and not has_content? -> "card card-image "
        not has_image? and has_content? -> "card card-text "
        true -> "card "
      end

    assigns =
      assigns
      |> assign(has_image?: has_image?, has_content?: has_content?)
      |> assign(:class, base_class <> (assigns |> Map.get(:class, "")))
      |> assign_new(:content, fn -> [] end)
      |> assign_new(:footer, fn -> [] end)
      |> assign_new(:image, fn -> [] end)

    ~H"""
      <article class={@class}>
        <h1><%= render_slot(@header) %></h1>
        <%= if @has_content? do %><div class="content"><%= render_slot(@content) %></div><% end %>
        <%= if @has_image? do %><%= render_slot(@image) %><% end %>
        <div class="footer"><%= render_slot(@footer) %></div>
      </article>
    """
  end
end
