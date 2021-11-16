defmodule MediaWatch.Parsing do
  alias MediaWatch.Repo
  alias MediaWatch.Parsing.{ParsedSnapshot, ParsingServer}
  @parsed_preloads [:xml, :source]

  def get(id), do: ParsedSnapshot |> Repo.get(id) |> Repo.preload(snapshot: @parsed_preloads)

  def parse(snap, parsable), do: ParsingServer.parse(snap, parsable)
  def slice(snap, sliceable), do: ParsingServer.slice(snap, sliceable)
end
