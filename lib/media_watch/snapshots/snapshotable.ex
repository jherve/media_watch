defmodule MediaWatch.Snapshots.Snapshotable do
  @callback make_snapshot(MediaWatch.Catalog.Source.t()) ::
              {:ok, Ecto.Changeset.t()} | {:error, any()}
  @callback make_snapshot_and_insert(MediaWatch.Catalog.Source.t(), Ecto.Repo.t()) ::
              {:ok, MediaWatch.Snapshots.Snapshot} | {:error, any()}
end
