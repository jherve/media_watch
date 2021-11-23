defmodule MediaWatch.Analysis.EntityRecognitionOperation do
  alias MediaWatch.{Repo, OperationWithRetry}
  alias MediaWatch.Parsing.Slice
  alias __MODULE__
  @behaviour OperationWithRetry
  @errors_with_retry [:database_busy]
  @max_db_retries 20

  @type error_reason :: :max_db_retries
  @type t :: %EntityRecognitionOperation{
          slice: Slice.t(),
          module: atom(),
          entities_cs: [Ecto.Changeset.t()] | nil,
          retry_strategy: OperationWithRetry.retry_strategy_fun(),
          retries: any()
        }

  @derive {Inspect, except: [:slice]}
  defstruct [:slice, :module, :entities_cs, :retries, :retry_strategy]

  @spec new(Slice.t(), atom()) :: EntityRecognitionOperation.t()
  def new(slice = %Slice{}, module),
    do:
      %EntityRecognitionOperation{
        slice: slice |> Repo.preload(Slice.preloads()),
        module: module
      }
      |> set_retry_strategy(&default_strategy/2)
      |> OperationWithRetry.init_retries(@errors_with_retry)

  defdelegate set_retry_strategy(operation, retry_fun), to: OperationWithRetry

  @impl OperationWithRetry
  def run(
        operation = %EntityRecognitionOperation{
          slice: slice,
          module: recognisable,
          entities_cs: nil
        }
      ) do
    with cs_list when is_list(cs_list) <- slice |> recognisable.get_entities_cs(),
         filtered when is_list(filtered) <- cs_list |> maybe_filter(recognisable) do
      %{operation | entities_cs: filtered} |> run
    end
  end

  def run(operation = %EntityRecognitionOperation{entities_cs: entities_cs})
      when is_list(entities_cs) do
    case Repo.safe_transaction(fn repo -> entities_cs |> Enum.map(&repo.insert(&1)) end) do
      {:ok, res} -> res
      {:error, :database_busy} -> operation |> OperationWithRetry.maybe_retry(:database_busy)
    end
  end

  defp default_strategy(:database_busy, retries) when retries < @max_db_retries, do: :retry
  defp default_strategy(_, _), do: :abort

  defp maybe_filter(cs_list, recognisable) when is_list(cs_list),
    do: cs_list |> Enum.reject(&maybe_blacklist(&1, recognisable))

  defp maybe_blacklist(cs, recognisable) do
    if function_exported?(recognisable, :in_entities_blacklist?, 1) do
      case cs |> Ecto.Changeset.fetch_field(:label) do
        {_, label} -> apply(recognisable, :in_entities_blacklist?, [label])
        :error -> false
      end
    else
      false
    end
  end
end
