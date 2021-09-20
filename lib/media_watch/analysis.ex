defmodule MediaWatch.Analysis do
  import Ecto.Query
  alias MediaWatch.{Repo, Catalog, PubSub}
  alias MediaWatch.Parsing.{ParsedSnapshot, Slice}
  alias MediaWatch.Snapshots.Snapshot
  alias MediaWatch.Catalog.Source

  def subscribe(item_id),
    do:
      Catalog.get_source_ids(item_id)
      |> Enum.map(&PubSub.subscribe("slicing:#{&1}"))
end
