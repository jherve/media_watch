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

  def parse_and_insert(snap, parsable) do
    snap = snap |> Repo.preload([:source, :xml])
    with {:ok, cs} <- parsable.parse(snap), do: cs |> Repo.insert_and_retry()
  end

  def slice_and_insert(snap, sliceable) do
    with cs_list when is_list(cs_list) <- sliceable.slice(snap),
         do:
           cs_list
           |> Enum.with_index(fn cs, idx -> {idx, cs} end)
           |> Map.new()
           |> Slice.insert_all()
  end
end
