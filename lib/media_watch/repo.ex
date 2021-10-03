defmodule MediaWatch.Repo do
  use Ecto.Repo,
    otp_app: :media_watch,
    adapter: Ecto.Adapters.SQLite3

  require Logger

  @wait_times [3, 7, 10, 20, 40]

  def insert_and_retry(obj, repo),
    do: retry_operation_and_log(fn -> obj |> repo.insert end, "insertion")

  def update_and_retry(obj, repo),
    do: retry_operation_and_log(fn -> obj |> repo.update end, "update")

  defp retry_operation_and_log(fun, operation_type) do
    case retry_operation(fun) do
      {out, nb_retries, duration_ms} ->
        if duration_ms > 200 or nb_retries > 10,
          do:
            Logger.warning(
              "Busy database prevented #{operation_type} for #{duration_ms} ms after #{nb_retries} retries"
            )

        out

      out ->
        out
    end
  end

  defp retry_operation(fun, nb_retries \\ 0, start_of_transaction \\ Timex.now())
       when is_function(fun, 0) do
    out = fun.()

    if nb_retries == 0,
      do: out,
      else: {out, nb_retries, Timex.now() |> Timex.diff(start_of_transaction, :millisecond)}
  rescue
    e in Exqlite.Error ->
      case e do
        %{message: "Database busy"} ->
          @wait_times |> Enum.random() |> Process.sleep()
          retry_operation(fun, nb_retries + 1, start_of_transaction)

        _ ->
          reraise e, __STACKTRACE__
      end
  end
end
