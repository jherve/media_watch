import Config

# config/runtime.exs is executed for all environments, including
# during releases. It is executed after compilation and before the
# system starts, so it is typically used to load production configuration
# and secrets from environment variables or elsewhere. Do not define
# any compile-time configuration in here, as it won't be applied.
# The block below contains prod specific runtime configuration.
if config_env() == :prod do
  # The secret key base is used to sign/encrypt cookies and other secrets.
  # A default value is used in config/dev.exs and config/test.exs but you
  # want to use a different value for prod and you most likely don't want
  # to check this value into version control, so we use an environment
  # variable instead.
  secret_key_base =
    System.get_env("SECRET_KEY_BASE") ||
      raise """
      environment variable SECRET_KEY_BASE is missing.
      You can generate one by calling: mix phx.gen.secret
      """

  host =
    System.get_env("HOST") ||
      raise """
      environment variable HOST is missing.
      """

  port = String.to_integer(System.get_env("PORT") || "4000")

  spacy_host = System.get_env("SPACY_HOST") || raise "environment variable SPACY_HOST is missing."
  spacy_port = System.get_env("SPACY_PORT") || raise "environment variable SPACY_PORT is missing."
  spacy_port = spacy_port |> String.to_integer()

  config :media_watch, MediaWatchWeb.Endpoint,
    url: [host: host, port: port],
    http: [
      # Enable IPv6 and bind on all interfaces.
      # Set it to  {0, 0, 0, 0, 0, 0, 0, 1} for local network only access.
      # See the documentation on https://hexdocs.pm/plug_cowboy/Plug.Cowboy.html
      # for details about using IPv6 vs IPv4 and loopback vs public addresses.
      ip: {0, 0, 0, 0, 0, 0, 0, 0},
      port: port
    ],
    secret_key_base: secret_key_base,
    server: true

  config :media_watch, MediaWatch.Repo,
    database: "db.sqlite",
    busy_timeout: 0,
    pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10")

  config :media_watch, MediaWatch.Spacy, host: spacy_host, port: spacy_port
end
