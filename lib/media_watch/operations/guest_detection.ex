defmodule MediaWatch.Analysis.GuestDetectionOperation do
  import Ecto.Query
  alias Ecto.Multi
  alias MediaWatch.{Repo, OperationWithRetry}
  alias MediaWatch.Parsing.Slice
  alias MediaWatch.Analysis.ShowOccurrence
  alias MediaWatch.Analysis.ShowOccurrence.Invitation
  alias __MODULE__
  @behaviour OperationWithRetry
  @errors_with_retry [:database_busy]
  @max_db_retries 20
  @preloads [:detail, slices: Slice.preloads()]

  @type error_reason :: :max_db_retries
  @opaque t :: %GuestDetectionOperation{
            occurrence: ShowOccurrence.t(),
            recognisable: atom(),
            hosted: atom(),
            guests_cs: [Ecto.Changeset.t()] | nil,
            retry_strategy: OperationWithRetry.retry_strategy_fun(),
            retries: any()
          }

  @derive {Inspect, except: [:occurrence]}
  defstruct [:occurrence, :recognisable, :hosted, :guests_cs, :retries, :retry_strategy]

  @spec new(ShowOccurrence.t(), atom(), atom()) :: GuestDetectionOperation.t()
  def new(occurrence = %ShowOccurrence{}, recognisable, hosted),
    do:
      %GuestDetectionOperation{
        occurrence: occurrence |> Repo.preload(@preloads),
        recognisable: recognisable,
        hosted: hosted
      }
      |> set_retry_strategy(&default_strategy/2)
      |> OperationWithRetry.init_retries(@errors_with_retry)

  defdelegate set_retry_strategy(operation, retry_fun), to: OperationWithRetry

  @impl OperationWithRetry
  def run(operation = %GuestDetectionOperation{guests_cs: nil}),
    do: operation |> get_guests() |> run

  def run(operation = %GuestDetectionOperation{}),
    do: operation |> do_insertion()

  defp get_guests(
         operation = %GuestDetectionOperation{
           occurrence: occ,
           recognisable: recognisable,
           hosted: hosted
         }
       ) do
    with list_of_attrs <- recognisable.get_guests_attrs(occ, hosted),
         cs_list <- Invitation.get_guests_cs(occ, list_of_attrs) do
      %{operation | guests_cs: cs_list}
    end
  end

  defp do_insertion(operation = %GuestDetectionOperation{guests_cs: guests_cs})
       when is_list(guests_cs) do
    # We assume that guest detection is more reliable when more information has been
    # gathered, therefore invitations that already exist are simply deleted.
    multi =
      Multi.new()
      |> Multi.delete_all(
        :delete_existing,
        from(i in Invitation, where: i.show_occurrence_id == ^operation.occurrence.id)
      )

    case guests_cs
         |> Enum.with_index()
         |> Enum.reduce(multi, fn {cs, idx}, multi ->
           multi |> Multi.run(idx, &insert_guest(cs, &1, &2))
         end)
         |> Repo.safe_transaction() do
      {:error, e = :database_busy} -> OperationWithRetry.maybe_retry(operation, e)
      {:ok, res_map} -> res_map |> Map.values()
      e = {:error, _, _cs, _changes} -> e
    end
  end

  defp insert_guest(cs, repo, changes) when is_struct(cs, Ecto.Changeset) do
    case cs |> repo.insert() do
      ok = {:ok, _} ->
        ok

      e = {:error, _} ->
        e |> Invitation.rescue_error(repo) |> do_recovery(repo, changes)
    end
  end

  defp do_recovery({:error, {:person_exists, new_cs}}, repo, changes),
    do: new_cs |> insert_guest(repo, changes)

  defp do_recovery({:error, {:unique, invitation}}, _, _), do: {:ok, {:already, invitation}}
  defp do_recovery(e = {:error, _}, _, _), do: e

  defp default_strategy(:database_busy, retries) when retries < @max_db_retries, do: :retry
  defp default_strategy(_, _), do: :abort
end
