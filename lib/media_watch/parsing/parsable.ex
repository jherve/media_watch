defmodule MediaWatch.Parsing.Parsable do
  @callback parse(MediaWatch.Snapshots.Snapshot.t()) ::
              {:ok, Ecto.Changeset.t()} | {:error, any()}
  @callback parse_and_insert(MediaWatch.Snapshots.Snapshot.t(), Ecto.Repo.t()) ::
              {:ok, MediaWatch.Parsing.ParsedSnapshot.t()} | {:error, any()}

  defmacro __using__(_opts) do
    quote do
      @behaviour MediaWatch.Parsing.Parsable

      @impl true
      def parse_and_insert(snap, repo) do
        with {:ok, cs} <- parse(snap), do: cs |> MediaWatch.Repo.insert_and_retry(repo)
      end

      defoverridable parse_and_insert: 2
    end
  end
end
