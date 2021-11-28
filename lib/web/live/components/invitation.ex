defmodule MediaWatchWeb.InvitationLiveComponent do
  use MediaWatchWeb, :live_component
  alias MediaWatch.Analysis
  alias MediaWatchWeb.Component.Icon
  alias MediaWatchWeb.PersonLiveComponent

  @impl true
  def update(assigns = %{invitation: invitation}, socket),
    do:
      {:ok,
       socket
       |> assign(assigns)
       |> assign(person: invitation.person, verified?: invitation.verified?)
       |> assign_new(:display_edit_buttons, fn -> false end)}

  @impl true
  def handle_event("delete", _, socket = %{assigns: %{invitation: invitation}}) do
    :ok = Analysis.delete_invitation(invitation, true)
    socket.assigns.notify_parent.(invitation_deleted: invitation)

    {:noreply, socket}
  end

  def handle_event("confirm", _, socket = %{assigns: %{invitation: invitation}}) do
    :ok = Analysis.confirm_invitation(invitation)
    {:noreply, socket |> assign(verified?: true)}
  end

  @impl true
  def render(assigns),
    do: ~H"""
      <div class={"invitation #{if @verified?, do: "verified"}"}>
        <.live_component module={PersonLiveComponent} id={person_id(@invitation)} person={@person} wrap_in_link={true} />
        <%= if @verified? do %>
          <Icon.icon icon="ok" class="status" title="Cette invitation a été vérifiée"/>
        <% else %>
          <Icon.icon icon="question-mark" class="status" title="Cette invitation n'a pas encore été vérifiée"/>
        <% end %>
        <%= if @display_edit_buttons do %>
          <button phx-click="delete" phx-target={@myself}><Icon.icon icon="trash" title="Enlever"/></button>
        <% end %>
        <%= if @display_edit_buttons and not @verified? do %>
          <button phx-click="confirm" phx-target={@myself}><Icon.icon icon="check" title="Confirmer"/></button>
        <% end %>
      </div>
    """

  defp person_id(invitation), do: {:person, invitation.id, invitation.person_id}
end
