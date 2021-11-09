defmodule MediaWatch.Auth do
  alias Phoenix.Token
  alias __MODULE__
  @default_endpoint MediaWatchWeb.Endpoint
  # Admin token lasts 10 days
  @admin_token_expiration 60 * 60 * 24 * 10
  @open_bar_admin? Application.compile_env(:media_watch, Auth)
                   |> Keyword.get(:open_bar_admin?, false)

  @spec open_bar_admin?() :: boolean()
  def open_bar_admin?(), do: @open_bar_admin?

  @spec generate_admin_key() :: binary()
  def generate_admin_key(), do: Token.sign(@default_endpoint, "admin-access", :admin)

  @spec is_valid_admin_key?(binary()) :: boolean()
  def is_valid_admin_key?(token) do
    case Token.verify(@default_endpoint, "admin-access", token, max_age: @admin_token_expiration) do
      {:ok, :admin} -> true
      _ -> false
    end
  end
end
