defmodule MediaWatch.Parsing.Parsable do
  alias MediaWatch.Snapshots.Snapshot

  @callback parse_snapshot(Snapshot.t()) :: {:ok, map()} | {:error, any()}
  @callback prune_snapshot(map(), Snapshot.t()) :: {:ok, map()} | {:error, any()}
end
