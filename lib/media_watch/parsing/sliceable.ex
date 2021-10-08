defmodule MediaWatch.Parsing.Sliceable do
  @callback slice(MediaWatch.Parsing.ParsedSnapshot.t()) :: [Ecto.Changeset.t()]
  @callback into_slice_cs(map(), MediaWatch.Parsing.ParsedSnapshot.t()) :: Ecto.Changeset.t()
  @callback slice_and_insert(MediaWatch.Parsing.ParsedSnapshot.t(), Ecto.Repo.t()) ::
              {:ok, ok_res :: list(), unique_res :: list()}
              | {:error, ok_res :: list(), unique_res :: list(), error_res :: list()}

  defmacro __using__(_opts) do
    quote do
      @behaviour MediaWatch.Parsing.Sliceable

      @impl true
      def slice_and_insert(snap, repo) do
        with cs_list when is_list(cs_list) <- slice(snap),
             do:
               cs_list
               |> Enum.with_index(fn cs, idx -> {idx, cs} end)
               |> Map.new()
               |> insert_all_slices(repo)
      end

      # Insert all the slices contained in `cs_list`, discarding 'unique' errors.
      #
      # The operation occurs in an single translation, with the guarantee that
      # all the valid slices either have been inserted or are already present in the
      # database.
      defp insert_all_slices(cs_map, repo, failures_so_far \\ %{})

      defp insert_all_slices(cs_map, repo, failures_so_far) when cs_map == %{},
        do: {:error, [], [], failures_so_far |> Map.values()}

      defp insert_all_slices(cs_map, repo, failures_so_far) when is_map(cs_map) do
        case cs_map |> run_and_group_results(repo) do
          {:error, _, _, failures} ->
            # In case of a rollback, the transaction is attempted again, with all
            # the steps that led to an error removed.
            failed_steps = failures |> Map.keys()

            cs_map
            |> Enum.reject(fn {k, _} -> k in failed_steps end)
            |> Map.new()
            |> insert_all_slices(repo, failures_so_far |> Map.merge(failures))

          {:ok, ok, unique} ->
            if failures_so_far |> Enum.empty?(),
              do: {:ok, ok |> Map.values(), unique |> Map.values()},
              else:
                {:error, ok |> Map.values(), unique |> Map.values(),
                 failures_so_far |> Map.values()}
        end
      end

      defp run_and_group_results(cs_map, repo),
        do:
          cs_map
          |> into_multi()
          |> repo.transaction()
          |> group_multi_results()

      defp into_multi(cs_map) do
        alias Ecto.Multi

        cs_map
        |> Enum.reduce(Multi.new(), fn {name, cs}, multi ->
          multi
          |> Multi.run(name, fn repo, _ ->
            # All the operations within the transaction are assumed to be 'successful'
            # whatever their actual result, so that the whole transaction can complete.
            case MediaWatch.Repo.insert_and_retry(cs, repo)
                 |> MediaWatch.Parsing.Slice.get_error_reason() do
              u = {:unique, val} -> {:ok, u}
              e = {:error, _} -> {:ok, e}
              ok = {:ok, _} -> ok
            end
          end)
        end)
        |> Multi.run(:control_stage, &fail_if_any_failure/2)
      end

      defp fail_if_any_failure(repo, changes) do
        # If there is any actual error within the transaction's operations, the
        # final stage enforces a rollback.
        failures = changes |> Enum.filter(&match?({_, {:error, _}}, &1)) |> Map.new()
        if not (failures |> Enum.empty?()), do: {:error, nil}, else: {:ok, nil}
      end

      defp group_multi_results(res = {:error, :control_stage, nil, changes}) do
        res =
          changes
          |> Enum.group_by(&categorize_errors/1)
          |> Map.new(fn {k, v} -> {k, v |> Map.new()} end)

        {:error, res |> Map.get(:ok, %{}), res |> Map.get(:unique, %{}),
         res |> Map.get(:error, %{})}
      end

      defp group_multi_results(res = {:ok, changes}) do
        res =
          changes
          |> Map.drop([:control_stage])
          |> Enum.group_by(&categorize_errors/1)
          |> Map.new(fn {k, v} -> {k, v |> Map.new()} end)

        {:ok, res |> Map.get(:ok, %{}), res |> Map.get(:unique, %{})}
      end

      defp categorize_errors({_k, {:unique, _v}}), do: :unique
      defp categorize_errors({_k, {:error, _v}}), do: :error
      defp categorize_errors({_k, _v}), do: :ok

      defoverridable slice_and_insert: 2
    end
  end
end
