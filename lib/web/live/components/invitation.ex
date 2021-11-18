defmodule MediaWatchWeb.InvitationLiveComponent do
  use MediaWatchWeb, :live_component
  alias MediaWatchWeb.PersonLiveComponent

  @impl true
  def update(assigns = %{invitation: invitation}, socket),
    do: {:ok, socket |> assign(assigns) |> assign(person: invitation.person)}

  @impl true
  def render(assigns),
    do: ~H"""
      <div class="invitation">
        <.live_component module={PersonLiveComponent} id={person_id(@invitation)} person={@person} wrap_in_link={true} />
      </div>
    """

  defp person_id(invitation), do: {:person, invitation.show_occurrence_id, invitation.person_id}
end
