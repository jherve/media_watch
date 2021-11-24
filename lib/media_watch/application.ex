defmodule MediaWatch.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    children =
      [
        # Start the Ecto repository
        MediaWatch.Repo,
        # Start the Telemetry supervisor
        MediaWatchWeb.Telemetry,
        # Start the PubSub system
        {Phoenix.PubSub, name: MediaWatch.PubSub},
        # Start the Endpoint (http/https)
        MediaWatchWeb.Endpoint,
        {Finch, name: MediaWatch.Finch},
        MediaWatch.Scheduler
      ] ++ additional_children()

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: MediaWatch.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    MediaWatchWeb.Endpoint.config_change(changed, removed)
    :ok
  end

  defp additional_children() do
    # A dirty fix to ensure Item supervision tree is not started in testing mode
    if Application.get_env(:media_watch, MediaWatch.Repo)[:pool] == Ecto.Adapters.SQL.Sandbox do
      []
    else
      [MediaWatch.Catalog.CatalogSupervisor]
    end
  end
end
