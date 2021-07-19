defmodule MediaWatch.Repo do
  use Ecto.Repo,
    otp_app: :media_watch,
    adapter: Ecto.Adapters.SQLite3
end
