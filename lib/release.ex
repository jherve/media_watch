defmodule Release do
  require Logger
  @app :media_watch

  def create do
    load_app!()

    case repo().__adapter__.storage_up(repo().config) do
      :ok ->
        Logger.info("Database created")
        :up

      {:error, :already_up} ->
        Logger.info("Database already up")
        :already_up

      {:error, term} when is_binary(term) ->
        Logger.error("The database for #{inspect(repo())} couldn't be created: #{term}")

      {:error, term} ->
        Logger.error("The database for #{inspect(repo())} couldn't be created: #{inspect(term)}")
    end
  end

  def migrate do
    load_app!()
    {:ok, _, _} = Ecto.Migrator.with_repo(repo(), &Ecto.Migrator.run(&1, :up, all: true))
  end

  def install do
    create()
    migrate()
  end

  defp load_app!,
    do: unless(:ok == Application.ensure_loaded(@app), do: raise("Could not load application"))

  defp repo(), do: with([repo] <- Application.get_env(@app, :ecto_repos), do: repo)
end
