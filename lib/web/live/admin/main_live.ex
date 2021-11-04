defmodule MediaWatchWeb.AdminMainLive do
  use MediaWatchWeb, :live_view
  alias MediaWatch.{Spacy, Snapshots, Analysis, Auth}
  @spacy_heartbeat_period 1_000

  @impl true
  def mount(%{"token" => token}, _, socket) do
    if Auth.is_valid_admin_key?(token),
      do:
        {:ok,
         socket |> assign(auth: true, items: Analysis.get_all_analyzed_items()) |> spacy_heartbeat},
      else: {:ok, socket |> assign(auth: false)}
  end

  def mount(_, _, socket),
    do: {:ok, socket |> assign(auth: false)}

  @impl true
  def handle_info(:spacy_heartbeat, socket), do: {:noreply, socket |> spacy_heartbeat()}

  @impl true
  def handle_event("trigger_all_snapshots", %{}, socket) do
    Snapshots.do_all_snapshots()
    {:noreply, socket}
  end

  def handle_event("trigger_snapshots", %{"id" => id}, socket) do
    id = String.to_integer(id)

    socket.assigns.items
    |> Enum.find(&(&1.id == id))
    |> Map.get(:module)
    |> Snapshots.do_snapshots()

    {:noreply, socket}
  end

  @impl true
  def render(assigns = %{auth: false}),
    do: ~H"""
    <h1>Admin</h1>

    <p>Please use a valid token</p>
    """

  def render(assigns = %{auth: true}),
    do: ~H"""
    <h1>Admin</h1>

    <p>Spacy server is.. <%= if @spacy_is_alive?, do: "alive", else: "unavailable" %></p>
    <p><button phx-click="trigger_all_snapshots">Lancer tous les snapshots</button></p>
    <ul>
      <%= for i <- @items do %>
        <li><%= i.show.name %> : <button phx-click="trigger_snapshots" phx-value-id={i.id}>Lancer les snapshots</button></li>
      <% end %>
    </ul>
    """

  defp spacy_heartbeat(socket) do
    Process.send_after(self(), :spacy_heartbeat, @spacy_heartbeat_period)
    socket |> assign(spacy_is_alive?: Spacy.is_alive?())
  end
end
