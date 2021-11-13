defmodule MediaWatch.Parsing do
  alias MediaWatch.Repo
  alias MediaWatch.Parsing.{Parsable, Sliceable, ParsedSnapshot}
  @parsed_preloads [:xml, :source]

  def get(id), do: ParsedSnapshot |> Repo.get(id) |> Repo.preload(snapshot: @parsed_preloads)

  defdelegate parse_and_insert(snap, parsable), to: Parsable
  defdelegate slice_and_insert(snap, sliceable), to: Sliceable
end
