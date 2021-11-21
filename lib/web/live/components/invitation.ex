defmodule MediaWatchWeb.InvitationLiveComponent do
  use MediaWatchWeb, :live_component
  alias MediaWatch.Analysis
  alias MediaWatchWeb.PersonLiveComponent

  @impl true
  def update(assigns = %{invitation: invitation}, socket),
    do:
      {:ok,
       socket
       |> assign(assigns)
       |> assign(person: invitation.person)
       |> assign_new(:display_delete_button, fn -> false end)}

  @impl true
  def handle_event("delete", _, socket = %{assigns: %{invitation: invitation}}) do
    :ok = Analysis.delete_invitation(invitation, true)
    socket.assigns.notify_parent.(invitation_deleted: invitation)

    {:noreply, socket}
  end

  @impl true
  def render(assigns),
    do: ~H"""
      <div class="invitation">
        <.live_component module={PersonLiveComponent} id={person_id(@invitation)} person={@person} wrap_in_link={true} />
        <%= if @display_delete_button do %><button phx-click="delete" phx-target={@myself}>Enlever</button><% end %>
      </div>
    """

  defp person_id(invitation), do: {:person, invitation.id, invitation.person_id}
end
