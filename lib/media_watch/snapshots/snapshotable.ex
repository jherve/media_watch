defmodule MediaWatch.Snapshots.Snapshotable do
  @callback get_snapshot(any()) :: {:ok, Ecto.Changeset.t()} | {:error, atom()}
end
