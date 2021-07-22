defmodule MediaWatch.Snapshots.Snapshotable do
  @callback get_snapshot(any()) :: {:ok, binary()} | {:error, atom()}
end
