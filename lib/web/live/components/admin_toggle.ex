defmodule MediaWatchWeb.AdminToggleLiveComponent do
  use MediaWatchWeb, :live_component
  alias __MODULE__

  @impl true
  def mount(socket) do
    cs = changeset()
    {:ok, socket |> assign(display_admin?: cs |> extract_value(), changeset: cs)}
  end

  @impl true
  def handle_event("change", %{"admin_toggle" => params}, socket) do
    cs = params |> changeset()

    {:noreply,
     socket |> assign(display_admin?: cs |> extract_value, changeset: cs) |> notify_toggle()}
  end

  defp notify_toggle(socket = %{assigns: %{display_admin?: display_admin?}}) do
    send(self(), {:display_admin?, display_admin?})
    socket
  end

  def as_component(assigns),
    do: ~H"""
      <%= if @admin do %><.live_component module={AdminToggleLiveComponent} id="admin_toggle"/><% end %>
    """

  @impl true
  def render(assigns),
    do: ~H"""
      <div id="admin-toggle">
        <.form
          let={f}
          for={@changeset}
          as="admin_toggle"
          id="admin-toggle-form"
          phx-target={@myself}
          phx-change="change">

          <%= label f, :display_admin?, "Activer les commandes admin ?" %>
          <%= checkbox f, :display_admin? %>
        </.form>
      </div>
    """

  defp changeset(params \\ %{}) do
    types = %{display_admin?: :boolean}

    {%{display_admin?: false}, types}
    |> Ecto.Changeset.cast(params, Map.keys(types))
  end

  defp extract_value(cs) do
    with {:ok, %{display_admin?: display_admin?}} <- cs |> Ecto.Changeset.apply_action(:validate),
         do: display_admin?
  end
end
