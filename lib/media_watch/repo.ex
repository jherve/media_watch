defmodule MediaWatch.Repo do
  use Ecto.Repo,
    otp_app: :media_watch,
    adapter: Ecto.Adapters.SQLite3

  require Logger

  @wait_times [3, 7, 10, 20, 40]

  def insert_and_retry(obj, repo, nb_retries \\ 0, start_of_transaction \\ Timex.now()) do
    out = obj |> repo.insert

    if nb_retries > 1 do
      duration_ms = Timex.now() |> Timex.diff(start_of_transaction, :millisecond)

      if duration_ms > 200 or nb_retries > 10,
        do:
          Logger.warning(
            "Busy database prevented insertion for #{duration_ms} ms after #{nb_retries} retries"
          )
    end

    out
  rescue
    e in Exqlite.Error ->
      case e do
        %{message: "Database busy"} ->
          @wait_times |> Enum.random() |> Process.sleep()
          insert_and_retry(obj, repo, nb_retries + 1, start_of_transaction)

        _ ->
          reraise e, __STACKTRACE__
      end
  end
end
