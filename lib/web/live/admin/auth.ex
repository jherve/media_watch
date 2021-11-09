defmodule MediaWatchWeb.Auth do
  import Phoenix.LiveView
  alias MediaWatch.Auth

  def on_mount(:default, _, _, socket),
    do: {:cont, socket |> assign(open_bar_admin?: Auth.open_bar_admin?())}
end
