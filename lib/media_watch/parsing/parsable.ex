defmodule MediaWatch.Parsing.Parsable do
  @callback parse(MediaWatch.Snapshots.Snapshot.t()) ::
              {:ok, Ecto.Changeset.t()} | {:error, any()}
  @callback parse_and_insert(MediaWatch.Snapshots.Snapshot.t(), Ecto.Repo.t()) ::
              {:ok, MediaWatch.Parsing.ParsedSnapshot.t()} | {:error, any()}
end
