defmodule MediaWatchWebPlugs do
  import Plug.Conn
  alias MediaWatch.Auth

  def check_admin(conn = %{params: %{"token" => token}}, _) do
    cond do
      Auth.open_bar_admin?() ->
        conn |> assign(:open_bar_admin?, true) |> assign(:admin, true)

      Auth.is_valid_admin_key?(token) ->
        conn |> assign(:open_bar_admin?, false) |> assign(:admin, true)

      true ->
        conn |> unauthorized()
    end
  end

  def check_admin(conn, _) do
    if Auth.open_bar_admin?(),
      do: conn |> assign(:open_bar_admin?, true) |> assign(:admin, true),
      else: conn |> unauthorized()
  end

  defp unauthorized(conn),
    do:
      conn
      |> put_status(:unauthorized)
      |> Phoenix.Controller.html("<h1>Please provide a valid token</h1>")
      |> halt()
end
