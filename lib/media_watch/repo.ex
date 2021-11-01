defmodule MediaWatch.Repo do
  use Ecto.Repo,
    otp_app: :media_watch,
    adapter: Ecto.Adapters.SQLite3

  alias Ecto.Multi
  alias MediaWatch.RecoverableMulti
  alias __MODULE__

  require Logger

  @wait_times [3, 7, 10, 20, 40]

  def insert_and_retry(obj),
    do: retry_operation_and_log(fn -> obj |> Repo.insert() end, "insertion")

  def update_and_retry(obj),
    do: retry_operation_and_log(fn -> obj |> Repo.update() end, "update")

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

  @doc """
  Run a transaction with automatic recovery of some errors.
  """
  @spec transaction_with_recovery(Multi.t()) ::
          {:ok, ok_results :: [any()], ignored :: [Ecto.Changeset.t()]}
          | {:error, ok_results :: [any()], ignored :: [Ecto.Changeset.t()],
             errors :: [Ecto.Changeset.t()]}
  def transaction_with_recovery(multi, failures_so_far \\ %{}, ignored_so_far \\ %{})

  def transaction_with_recovery(multi = %Multi{}, failures_so_far, ignored_so_far),
    do:
      transaction_with_recovery(
        multi,
        failures_so_far,
        ignored_so_far,
        multi |> RecoverableMulti.is_empty?()
      )

  def transaction_with_recovery(_, failures_so_far, ignored_so_far, true),
    do: return_result(%{}, ignored_so_far, failures_so_far)

  def transaction_with_recovery(multi, failures_so_far, ignored_so_far, false) do
    case multi |> Repo.transaction() |> RecoverableMulti.wrap_transaction_result() do
      {:error, _, ignored, failures} ->
        # In case of a rollback, the transaction is attempted again, with all
        # the steps that led to an error removed.
        failed_steps = failures |> Map.keys()
        ignored_steps = ignored |> Map.keys()

        multi
        |> RecoverableMulti.remove_steps(failed_steps ++ ignored_steps)
        |> transaction_with_recovery(
          failures_so_far |> Map.merge(failures),
          ignored_so_far |> Map.merge(ignored)
        )

      {:ok, ok} ->
        return_result(ok, ignored_so_far, failures_so_far)
    end
  end

  defp return_result(ok, ignored, failures)
       when is_map(ok) and is_map(ignored) and is_map(failures),
       do: return_result(ok |> Map.values(), ignored |> Map.values(), failures |> Map.values())

  defp return_result(ok, ignored, []) when is_list(ok) and is_list(ignored),
    do: {:ok, ok, ignored}

  defp return_result(ok, ignored, failures)
       when is_list(ok) and is_list(ignored) and is_list(failures),
       do: {:error, ok, ignored, failures}
end
