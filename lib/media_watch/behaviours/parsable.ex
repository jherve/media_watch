defmodule MediaWatch.Parsing.Parsable do
  alias MediaWatch.Repo
  alias MediaWatch.Snapshots.Snapshot
  alias MediaWatch.Parsing.ParsedSnapshot

  @callback parse_snapshot(Snapshot.t()) :: {:ok, map()} | {:error, any()}
  @callback prune_snapshot(map(), Snapshot.t()) :: {:ok, map()} | {:error, any()}

  def parse(snap = %Snapshot{}, parsable) do
    with {:ok, parsed} <- snap |> parsable.parse_snapshot(),
         {:ok, pruned} <- parsed |> parsable.prune_snapshot(snap) do
      {:ok,
       ParsedSnapshot.changeset(%ParsedSnapshot{snapshot: snap, source: snap.source}, %{
         data: pruned
       })}
    end
  end

  def parse_and_insert(snap, parsable) do
    snap = snap |> Repo.preload([:source, :xml])
    with {:ok, cs} <- parse(snap, parsable), do: cs |> Repo.insert()
  end
end
