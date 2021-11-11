defmodule MediaWatchWeb.Router do
  use MediaWatchWeb, :router
  import MediaWatchWebPlugs
  import Phoenix.LiveDashboard.Router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {MediaWatchWeb.LayoutView, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :transfer_admin_token_to_session
    plug :check_admin
  end

  pipeline :admin do
    plug :enforce_admin
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", MediaWatchWeb do
    pipe_through :browser

    live "/", PageLive, :index
    live "/changes", ChangelogLive, :index
    live "/items", ItemIndexLive, :index
    live "/items/:id", ItemLive, :detail
    live "/show_occurrences", ShowOccurrenceIndexLive, :index
    live "/persons", PersonIndexLive, :index
  end

  scope "/admin", MediaWatchWeb do
    pipe_through [:browser, :admin]

    live_session :default, on_mount: MediaWatchWeb.Auth do
      live "/", AdminMainLive, :index
    end
  end

  scope "/dashboard" do
    pipe_through [:browser, :admin]
    live_dashboard "/", metrics: MediaWatchWeb.Telemetry
  end
end
