defmodule MediaWatch.Parsing do
  import Ecto.Query
  alias MediaWatch.Repo
  alias MediaWatch.Parsing.{ParsedSnapshot, Slice}
  @parsed_preloads [:xml, :source]

  def get_parsed(source_id),
    do: from(p in ParsedSnapshot, where: p.source_id == ^source_id) |> Repo.all()

  def get_slices(source_ids) when is_list(source_ids),
    do: from(s in Slice, where: s.source_id in ^source_ids) |> Repo.all()

  def get_slices(source_id), do: from(s in Slice, where: s.source_id == ^source_id) |> Repo.all()

  def get(id), do: ParsedSnapshot |> Repo.get(id) |> Repo.preload(snapshot: @parsed_preloads)

  def get_all(), do: ParsedSnapshot |> Repo.all() |> Repo.preload(snapshot: @parsed_preloads)
end
