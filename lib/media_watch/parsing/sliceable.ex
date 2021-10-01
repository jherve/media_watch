defmodule MediaWatch.Parsing.Sliceable do
  @callback slice(MediaWatch.Parsing.ParsedSnapshot.t()) :: [
              {:ok, Ecto.Changeset.t()} | {:error, atom()}
            ]
  @callback slice_and_insert(MediaWatch.Parsing.ParsedSnapshot.t(), Ecto.Repo.t()) ::
              {:ok, ok_res :: list(), unique_res :: list()}
              | {:error, ok_res :: list(), unique_res :: list(), error_res :: list()}

  defmacro __using__(_opts) do
    quote do
      @behaviour MediaWatch.Parsing.Sliceable

      @impl true
      def slice_and_insert(snap, repo) do
        with cs_list when is_list(cs_list) <- slice(snap), do: cs_list |> insert_all_slices(repo)
      end

      defp insert_all_slices(cs_list, repo) do
        res =
          cs_list
          |> Enum.map(&MediaWatch.Repo.insert_and_retry(&1, repo))
          |> Enum.group_by(&MediaWatch.Parsing.Slice.get_error_reason/1, fn {_, val} -> val end)

        {ok, unique, failures} =
          {res |> Map.get(:ok, []), res |> Map.get(:unique, []), res |> Map.get(:error, [])}

        if failures |> Enum.empty?(), do: {:ok, ok, unique}, else: {:error, ok, unique, failures}
      end

      defoverridable slice_and_insert: 2
    end
  end
end
