defmodule MediaWatch.Parsing do
  require Logger
  alias MediaWatch.Repo
  alias MediaWatch.Parsing.{ParsedSnapshot, ParsingOperation, SlicingOperation}
  @parsed_preloads [:xml, :source]

  def get(id), do: ParsedSnapshot |> Repo.get(id) |> Repo.preload(snapshot: @parsed_preloads)

  def parse(snap, parsable),
    do:
      ParsingOperation.new(snap, parsable)
      |> ParsingOperation.set_retry_strategy(fn :database_busy, _ -> :retry_exp end)
      |> ParsingOperation.run()

  def slice(_parsed = %{id: id}, sliceable),
    do:
      get(id)
      |> SlicingOperation.new(sliceable)
      |> SlicingOperation.set_retry_strategy(fn :database_busy, _ -> :retry_exp end)
      |> SlicingOperation.run()
end
