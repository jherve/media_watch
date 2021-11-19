defmodule MediaWatchWeb.ShowOccurrenceLiveComponent do
  use MediaWatchWeb, :live_component
  alias MediaWatch.{DateTime, Analysis}
  alias MediaWatchWeb.Component.{List, Card}
  alias MediaWatchWeb.{ItemView, ShowOccurrenceView}
  alias MediaWatchWeb.InvitationLiveComponent
  alias __MODULE__
  @truncated_length 100

  @impl true
  def mount(socket),
    do: {:ok, socket |> assign(truncate_description: true, display_add_guest_form: false)}

  @impl true
  def update(assigns = %{occurrence: occ = %{detail: detail}}, socket) do
    airing_day = occ.airing_time |> Timex.to_date()

    {:ok,
     socket
     |> assign(assigns)
     |> assign(
       # In some rare cases the `detail` may be nil because it could not be interpreted correctly
       title:
         if(detail, do: detail.title, else: "Émission du #{airing_day |> DateTime.to_string()}"),
       description: if(detail, do: detail.description),
       invitations: occ.invitations,
       guests: occ.guests,
       external_link_to_occurrence: if(detail, do: detail.link),
       link_to_item: ItemView.detail_link(occ.show_id),
       airing_time: occ.airing_time,
       airing_day: airing_day,
       send_update: fn params ->
         send_update(ShowOccurrenceLiveComponent, params |> Keyword.merge(id: assigns.id))
       end,
       guest_addition_cs: Analysis.changeset_for_guest_addition(occ)
     )
     |> assign_new(:image_url, fn -> nil end)
     |> assign_new(:display_link_to_item, fn -> false end)
     |> assign_new(:display_link_to_date, fn -> false end)
     |> assign_new(:can_edit_invitations?, fn -> false end)}
  end

  def update(%{invitation_deleted: invitation}, socket) do
    is_deleted? = fn tested ->
      tested.show_occurrence_id == invitation.show_occurrence_id and
        tested.person_id == invitation.person_id
    end

    {:ok, socket |> update(:invitations, &(&1 |> Enum.reject(is_deleted?)))}
  end

  @impl true
  def handle_event("toggle_truncate", _, socket),
    do: {:noreply, socket |> update(:truncate_description, &(not &1))}

  def handle_event("show_guest_form", _, socket),
    do: {:noreply, socket |> assign(display_add_guest_form: true)}

  def handle_event("hide_guest_form", _, socket),
    do: {:noreply, socket |> assign(display_add_guest_form: false)}

  def handle_event("save", %{"guest_addition" => params}, socket) do
    case Analysis.changeset_for_guest_addition(socket.assigns.occurrence, params)
         |> Analysis.do_guest_addition() do
      {:ok, new_invitation} ->
        {:noreply, socket |> update(:invitations, &(&1 ++ [new_invitation]))}

      {:error, cs = %Ecto.Changeset{}} ->
        {:noreply, socket |> assign(guest_addition_cs: cs)}
    end
  end

  @impl true
  def render(assigns),
    do: ~H"""
      <div>
        <Card.card class="occurrence">
          <:header><%= @title %></:header>

          <:content>
            <%= render_invitations(assigns) %>
            <%= render_guest_form_toggle(assigns) %>
            <%= render_add_guest_form(assigns) %>
            <p phx-click="toggle_truncate" phx-target={@myself}><%= render_description(assigns) %></p>
            <%= if @display_link_to_item, do: live_redirect("Toutes les émissions", to: @link_to_item) %>
            <%= if @external_link_to_occurrence, do: link("Lien vers l'émission", to: @external_link_to_occurrence) %>
          </:content>

          <:image><%= if @image_url do %><img src={@image_url}><% end %></:image>

          <:footer><%= render_airing_time(assigns) %></:footer>
        </Card.card>
      </div>
    """

  defp render_invitations(assigns = %{invitations: []}),
    do: ~H|<div class="guests">Pas d'invités detectés</div>|

  defp render_invitations(assigns),
    do: ~H"""
    <List.ul let={invitation} list={@invitations} class="invitations">
      <.live_component module={InvitationLiveComponent}
                       id={invitation_id(invitation)}
                       invitation={invitation}
                       display_delete_button={@can_edit_invitations?}
                       notify_parent={@send_update} />
    </List.ul>
    """

  defp invitation_id(invitation),
    do: {:invitation, invitation.show_occurrence_id, invitation.person_id}

  defp render_guest_form_toggle(assigns = %{can_edit_invitations?: true}),
    do: ~H"""
      <button phx-click="show_guest_form" phx-target={@myself}>Ajouter un(e) invité(e)</button>
    """

  defp render_guest_form_toggle(assigns), do: ~H""

  defp render_add_guest_form(assigns = %{display_add_guest_form: true}),
    do: ~H"""
    <.form
        let={f}
        for={@guest_addition_cs}
        id="add-guest-form"
        phx-target={@myself}
        phx-submit="save">

        <%= label f, :person_label, "Nom" %>
        <%= text_input f, :person_label %>
        <%= error_tag f, :person_label %>

        <div>
          <%= submit "Ajouter", phx_disable_with: "En cours..." %>
          <button type="button" phx-click="hide_guest_form" phx-target={@myself}>Fermer</button>
        </div>
      </.form>
    """

  defp render_add_guest_form(assigns), do: ~H""

  defp render_description(assigns = %{description: nil}), do: ~H"Pas de description disponible"

  defp render_description(assigns = %{truncate_description: true}),
    do: ~H"<%= truncate(@description) %>"

  defp render_description(assigns = %{truncate_description: false}), do: ~H"<%= @description %>"

  defp render_airing_time(assigns = %{display_link_to_date: true}),
    do:
      ~H[<%= live_redirect @airing_day |> DateTime.to_string(), to: ShowOccurrenceView.link_by_date(@airing_day) %>]

  defp render_airing_time(assigns), do: ~H[<%= @airing_day |> DateTime.to_string() %>]

  defp truncate(string, max \\ @truncated_length) do
    length = string |> String.length()
    if length > max, do: "#{string |> String.slice(0..max)}...", else: string
  end
end
