defmodule MediaWatch.Snapshots.Snapshotable do
  @callback make_snapshot(any()) :: {:ok, Ecto.Changeset.t()} | {:error, atom()}
end
