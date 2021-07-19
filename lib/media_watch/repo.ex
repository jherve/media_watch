defmodule MediaWatch.Repo do
  use Ecto.Repo,
    otp_app: :media_watch,
    adapter: Ecto.Adapters.Postgres
end
