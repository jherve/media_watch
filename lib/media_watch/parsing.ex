defmodule MediaWatch.Parsing do
  alias MediaWatch.Repo
  alias MediaWatch.Snapshots.Snapshot
  alias MediaWatch.Parsing.ParsedSnapshot
  @parsed_preloads [:xml, :source]

  def do_parsing(snap = %Snapshot{}),
    do: with({:ok, cs} <- Snapshot.parse(snap), do: cs |> Repo.insert())

  def get(id), do: ParsedSnapshot |> Repo.get(id) |> Repo.preload(snapshot: @parsed_preloads)
  def get_all(), do: ParsedSnapshot |> Repo.all() |> Repo.preload(snapshot: @parsed_preloads)
end
