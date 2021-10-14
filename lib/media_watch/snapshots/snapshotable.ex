defmodule MediaWatch.Snapshots.Snapshotable do
  @callback make_snapshot(MediaWatch.Catalog.Source.t()) ::
              {:ok, Ecto.Changeset.t()} | {:error, any()}
end
