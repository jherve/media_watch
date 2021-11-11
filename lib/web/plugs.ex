defmodule MediaWatchWeb.Plugs do
  import Plug.Conn
  alias MediaWatch.Auth
  @token_key "_admin_token"

  def check_admin(conn, _) do
    open_bar? = Auth.open_bar_admin?()

    token_valid? =
      case conn |> get_session(@token_key) do
        nil -> false
        token -> Auth.is_valid_admin_key?(token)
      end

    conn |> assign(:open_bar_admin?, open_bar?) |> assign(:admin, token_valid? or open_bar?)
  end

  def enforce_admin(conn = %{assigns: %{admin: true}}, _), do: conn
  def enforce_admin(conn, _), do: conn |> unauthorized()

  defp unauthorized(conn),
    do:
      conn
      |> put_status(:unauthorized)
      |> Phoenix.Controller.html("<h1>Please provide a valid token</h1>")
      |> halt()

  def transfer_admin_token_to_session(conn = %{params: %{"token" => token}}, _),
    do: conn |> put_session(@token_key, token)

  def transfer_admin_token_to_session(conn, _), do: conn
end
