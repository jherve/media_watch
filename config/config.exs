# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :media_watch,
  ecto_repos: [MediaWatch.Repo]

# Configures the endpoint
config :media_watch, MediaWatchWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "KjL+azW62hOaH7v7GKD4fUMFp7Vyl5zvUcOz/yVNRxW+QyYEel1Te74y0RJpNHVB",
  render_errors: [view: MediaWatchWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: MediaWatch.PubSub,
  live_view: [signing_salt: "3h6ftnMH"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

config :esbuild,
  version: "0.13.12",
  default: [
    args: ~w(js/app.js --bundle --target=es2016 --outdir=../priv/static/assets),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

config :media_watch, MediaWatch.Auth, open_bar_admin?: false

import_config "inventory.exs"

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
