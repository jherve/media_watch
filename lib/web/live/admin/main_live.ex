defmodule MediaWatchWeb.AdminMainLive do
  use MediaWatchWeb, :live_view
  alias MediaWatch.{Spacy, Snapshots, Analysis, Utils}
  @spacy_heartbeat_period 10_000

  @impl true
  def mount(_, _, socket = %{assigns: %{open_bar_admin?: open_bar_admin?}}),
    do:
      {:ok,
       socket
       |> assign(items: Analysis.get_all_analyzed_items(), display_nuke_command: open_bar_admin?)
       |> spacy_heartbeat}

  @impl true
  def handle_info(:spacy_heartbeat, socket), do: {:noreply, socket |> spacy_heartbeat()}

  @impl true
  def handle_event("trigger_all_snapshots", %{}, socket) do
    Snapshots.do_all_snapshots()
    {:noreply, socket}
  end

  def handle_event("restart_catalog", %{}, socket) do
    Utils.restart_catalog()
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

  def handle_event("nuke_database", %{}, socket) do
    Utils.nuke_database()
    {:noreply, socket}
  end

  @impl true
  def render(assigns),
    do: ~H"""
    <h1>Admin</h1>

    <p>Spacy server is.. <%= if @spacy_is_alive?, do: "alive", else: "unavailable" %></p>
    <p><button phx-click="trigger_all_snapshots">Lancer tous les snapshots</button></p>
    <p><button phx-click="restart_catalog">Redémarrer tout le catalogue</button></p>
    <ul>
      <%= for i <- @items do %>
        <li><%= i.show.name %> : <button phx-click="trigger_snapshots" phx-value-id={i.id}>Lancer les snapshots</button></li>
      <% end %>
    </ul>
    <%= if @display_nuke_command do %>
      <p><button class="alert-danger"
                 phx-click="nuke_database"
                 data-confirm="Êtes-vous SÛR de vouloir faire ça?">Reset de la database</button></p>
    <% end %>
    """

  defp spacy_heartbeat(socket) do
    Process.send_after(self(), :spacy_heartbeat, @spacy_heartbeat_period)
    socket |> assign(spacy_is_alive?: Spacy.is_alive?())
  end
end
