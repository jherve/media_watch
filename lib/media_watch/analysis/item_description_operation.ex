defmodule MediaWatch.Analysis.ItemDescriptionOperation do
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
            slice_type: atom(),
            describable: atom(),
            description_cs: Ecto.Changeset.t() | nil,
            description: Description.t() | nil,
            retry_strategy: OperationWithRetry.retry_strategy_fun(),
            retries: any()
          }

  @derive {Inspect, except: [:slice, :description, :description_cs, :retry_strategy]}
  defstruct [
    :slice,
    :slice_type,
    :describable,
    :description_cs,
    :description,
    :retries,
    :retry_strategy
  ]

  @spec new(Slice.t(), atom(), module()) :: ItemDescriptionOperation.t()
  def new(slice = %Slice{}, slice_type, describable),
    do:
      %ItemDescriptionOperation{
        slice: slice |> Repo.preload(Slice.preloads()),
        slice_type: slice_type,
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

  def run(operation = %ItemDescriptionOperation{description_cs: cs, description: nil}) do
    case cs |> Repo.safe_insert() |> Description.handle_error(Repo) do
      {:ok, desc} -> %{operation | description: desc} |> run
      {:error, {:unique, desc}} -> {:already, desc}
      {:error, e = :database_busy} -> OperationWithRetry.maybe_retry(operation, e)
      e = {:error, _} -> e
    end
  end

  def run(
        operation = %ItemDescriptionOperation{
          slice: %{id: slice_id},
          description: description = %{item_id: description_id},
          slice_type: type
        }
      ) do
    case %{slice_id: slice_id, description_id: description_id, type: type}
         |> SliceUsage.create_changeset()
         |> Repo.safe_insert()
         |> SliceUsage.explain_error() do
      {:ok, _} -> {:ok, description}
      {:error, :unique} -> {:ok, description}
      {:error, e = :database_busy} -> OperationWithRetry.maybe_retry(operation, e)
      e = {:error, _} -> e
    end
  end

  defp default_strategy(:database_busy, retries) when retries < @max_db_retries, do: :retry
  defp default_strategy(_, _), do: :abort
end
