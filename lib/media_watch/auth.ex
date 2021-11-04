defmodule MediaWatch.Auth do
  alias Phoenix.Token
  @default_endpoint MediaWatchWeb.Endpoint
  @admin_token_expiration 60 * 15

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
