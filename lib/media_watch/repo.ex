defmodule MediaWatch.Repo do
  use Ecto.Repo,
    otp_app: :media_watch,
    adapter: Ecto.Adapters.SQLite3

  alias Ecto.Multi
  alias MediaWatch.RecoverableMulti
  alias __MODULE__

  require Logger

  @type transaction_result ::
          {:ok, ok_results :: [any()], ignored :: [Ecto.Changeset.t()]}
          | {:error, ok_results :: [any()], ignored :: [Ecto.Changeset.t()],
             errors :: [Ecto.Changeset.t()]}

  def safe_insert(obj), do: fn -> obj |> Repo.insert() end |> safe_operation()
  def safe_update(obj), do: fn -> obj |> Repo.update() end |> safe_operation()
  def safe_delete(obj), do: fn -> obj |> Repo.delete() end |> safe_operation()

  def safe_transaction(fun_or_multi)
      when is_function(fun_or_multi, 1) or is_struct(fun_or_multi, Multi),
      do: fn -> fun_or_multi |> Repo.transaction() end |> safe_operation()

  def safe_transaction_with_recovery(multi = %Multi{}),
    do: fn -> multi |> Repo.transaction_with_recovery() end |> safe_operation()

  defp safe_operation(fun) when is_function(fun, 0) do
    fun.()
  rescue
    e -> e |> handle_runtime_error(__STACKTRACE__)
  end

  defp handle_runtime_error(%Exqlite.Error{message: "Database busy"}, _),
    do: {:error, :database_busy}

  defp handle_runtime_error(%Exqlite.Error{message: "trigger:" <> error}, _) do
    [trigger_name, reason] = error |> String.split(":", parts: 2)
    {:error, {:trigger, trigger_name, reason}}
  end

  defp handle_runtime_error(e, stacktrace) when is_struct(e), do: reraise(e, stacktrace)

  @doc """
  Run a transaction with automatic recovery of some errors.
  """
  @spec transaction_with_recovery(Multi.t()) :: transaction_result()
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
