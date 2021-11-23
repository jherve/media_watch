defmodule MediaWatch.Analysis.ItemDescriptionOperation do
  alias Ecto.Multi
  alias MediaWatch.{Repo, OperationWithRetry, Catalog}
  alias MediaWatch.Parsing.Slice
  alias MediaWatch.Analysis.{Description, SliceUsage}
  alias __MODULE__
  @behaviour OperationWithRetry
  @errors_with_retry [:database_busy]
  @max_db_retries 20

  @type error_reason :: :max_db_retries
  @opaque t :: %ItemDescriptionOperation{
            slice: Slice.t(),
            describable: atom(),
            description_cs: Ecto.Changeset.t() | nil,
            description: Description.t() | nil,
            retry_strategy: OperationWithRetry.retry_strategy_fun(),
            retries: any()
          }

  @derive {Inspect, except: [:slice, :description, :description_cs, :retry_strategy]}
  defstruct [
    :slice,
    :describable,
    :description_cs,
    :multi,
    :description,
    :retries,
    :retry_strategy
  ]

  @spec new(Slice.t(), module()) :: ItemDescriptionOperation.t()
  def new(slice = %Slice{}, describable),
    do:
      %ItemDescriptionOperation{
        slice: slice |> Repo.preload(Slice.preloads()),
        describable: describable
      }
      |> set_retry_strategy(&default_strategy/2)
      |> OperationWithRetry.init_retries(@errors_with_retry)

  defdelegate set_retry_strategy(operation, retry_fun), to: OperationWithRetry

  @impl OperationWithRetry
  def run(
        operation = %ItemDescriptionOperation{
          slice: slice,
          describable: describable,
          description_cs: nil
        }
      ) do
    item_id = Catalog.item_id_from_source_id(slice.source_id)

    %{
      operation
      | description_cs:
          describable.get_description_attrs(item_id, slice)
          |> Description.changeset()
    }
    |> run
  end

  def run(operation = %ItemDescriptionOperation{multi: nil}) do
    %{operation | multi: create_multi(operation)} |> run()
  end

  def run(operation = %ItemDescriptionOperation{multi: multi = %Multi{}}) do
    case multi |> Repo.safe_transaction() do
      {:ok, %{insert_description: {:unique, desc}}} -> {:already, desc}
      {:ok, %{insert_description: desc}} -> {:ok, desc}
      {:error, e = :database_busy} -> OperationWithRetry.maybe_retry(operation, e)
      e = {:error, _, _, _} -> e
    end
  end

  defp create_multi(%ItemDescriptionOperation{
         description_cs: cs,
         slice: %{id: slice_id}
       }) do
    Multi.new()
    |> Multi.run(:insert_description, &insert_description(cs, &1, &2))
    |> Multi.run(:mark_slice_usage, &mark_slice_usage(%{slice_id: slice_id}, &1, &2))
  end

  defp insert_description(description_cs, repo, _changes) do
    case description_cs |> repo.insert() |> Description.handle_error(repo) do
      ok = {:ok, _} -> ok
      {:error, unique = {:unique, _}} -> {:ok, unique}
      e = {:error, _} -> e
    end
  end

  defp mark_slice_usage(slice_usage_attrs, repo, %{insert_description: res}) do
    description_id =
      case res do
        {:unique, desc} -> desc.item_id
        desc -> desc.item_id
      end

    case slice_usage_attrs
         |> Map.put(:description_id, description_id)
         |> SliceUsage.create_changeset()
         |> repo.insert()
         |> SliceUsage.explain_error() do
      ok = {:ok, _} -> ok
      {:error, :unique} -> {:ok, :unique}
      e = {:error, _} -> e
    end
  end

  defp default_strategy(:database_busy, retries) when retries < @max_db_retries, do: :retry
  defp default_strategy(_, _), do: :abort
end
