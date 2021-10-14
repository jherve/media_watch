defmodule MediaWatch.Parsing.Parsable do
  @callback parse(MediaWatch.Snapshots.Snapshot.t()) ::
              {:ok, Ecto.Changeset.t()} | {:error, any()}
end
