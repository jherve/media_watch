defmodule MediaWatch.Parsing.SlicingOperation do
  alias MediaWatch.{Repo, RecoverableMulti, OperationWithRetry}
  alias MediaWatch.Parsing.{ParsedSnapshot, Slice, Sliceable}
  alias __MODULE__
  @behaviour OperationWithRetry
  @errors_with_retry [:database_busy]
  @max_db_retries 20

  @type error_reason :: :max_db_retries
  @type t :: %SlicingOperation{
          parsed_snapshot: ParsedSnapshot.t(),
          module: atom(),
          retry_strategy: OperationWithRetry.retry_strategy_fun(),
          retries: any()
        }

  @derive {Inspect, except: [:parsed_snapshot]}
  defstruct [:parsed_snapshot, :module, :list_of_slices_cs, :retries, :retry_strategy]

  @spec new(ParsedSnapshot.t(), atom()) :: SlicingOperation.t()
  def new(snapshot = %ParsedSnapshot{}, module),
    do:
      %SlicingOperation{
        parsed_snapshot: snapshot |> Repo.preload(snapshot: [:source]),
        module: module
      }
      |> set_retry_strategy(&default_strategy/2)
      |> OperationWithRetry.init_retries(@errors_with_retry)

  defdelegate set_retry_strategy(operation, retry_fun), to: OperationWithRetry

  @impl OperationWithRetry
  def run(
        operation = %SlicingOperation{
          parsed_snapshot: snapshot,
          module: module,
          list_of_slices_cs: nil
        }
      ) do
    %{operation | list_of_slices_cs: snapshot |> Sliceable.slice(module)} |> run()
  end

  def run(operation = %SlicingOperation{list_of_slices_cs: list}) when is_list(list) do
    case list
         |> Slice.into_multi()
         |> RecoverableMulti.new(&wrap_result/1)
         |> Repo.safe_transaction_with_recovery() do
      {:error, :database_busy} -> operation |> OperationWithRetry.maybe_retry(:database_busy)
      any -> any
    end
  end

  defp default_strategy(:database_busy, retries) when retries < @max_db_retries, do: :retry
  defp default_strategy(_, _), do: :abort

  defp wrap_result(res), do: Slice.get_error_reason(res) |> maybe_ignore()

  defp maybe_ignore({:unique, val}), do: {:ignore, val}
  defp maybe_ignore(e_or_ok), do: e_or_ok
end
