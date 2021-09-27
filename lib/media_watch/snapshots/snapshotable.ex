defmodule MediaWatch.Snapshots.Snapshotable do
  @callback make_snapshot(MediaWatch.Catalog.Source.t()) ::
              {:ok, Ecto.Changeset.t()} | {:error, any()}
  @callback make_snapshot_and_insert(MediaWatch.Catalog.Source.t(), Ecto.Repo.t()) ::
              {:ok, MediaWatch.Snapshots.Snapshot} | {:error, any()}

  defmacro __using__(_opts) do
    quote do
      @behaviour MediaWatch.Snapshots.Snapshotable

      def make_snapshot_and_insert(source, repo) do
        with {:ok, cs} <- make_snapshot(source), do: cs |> MediaWatch.Repo.insert_and_retry(repo)
      end

      defoverridable make_snapshot_and_insert: 2
    end
  end
end
