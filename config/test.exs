import Config

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :media_watch, MediaWatch.Repo,
  database: "db-test.sqlite",
  pool: Ecto.Adapters.SQL.Sandbox,
  migration_source: "_migrations"

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :media_watch, MediaWatchWeb.Endpoint,
  http: [port: 4002],
  server: false

# Print only warnings and errors during test
config :logger, level: :warn
