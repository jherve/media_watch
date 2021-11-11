defmodule MediaWatchWeb.Auth do
  import Phoenix.LiveView
  alias MediaWatch.Auth
  alias MediaWatchWeb.Plugs

  def on_mount(:default, _, session, socket) do
    {:cont, socket |> set_admin_assigns(session)}
  end

  defp set_admin_assigns(socket, session) do
    open_bar? = Auth.open_bar_admin?()

    token_valid? =
      case session |> Map.get(Plugs.token_key()) do
        nil -> false
        token -> Auth.is_valid_admin_key?(token)
      end

    socket |> assign(:open_bar_admin?, open_bar?) |> assign(:admin, token_valid? or open_bar?)
  end
end
