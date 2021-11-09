defmodule MediaWatch.Parsing do
  import Ecto.Query
  alias MediaWatch.{Repo, RecoverableMulti}
  alias MediaWatch.Snapshots.Snapshot
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
    with {:ok, cs} <- Snapshot.parse(snap, parsable), do: cs |> Repo.insert()
  end

  def slice_and_insert(snap, sliceable) do
    with cs_list when is_list(cs_list) <- ParsedSnapshot.slice(snap, sliceable),
         do:
           cs_list
           |> Slice.into_multi()
           |> RecoverableMulti.new(&wrap_result/1)
           |> Repo.transaction_with_recovery()
  end

  defp wrap_result(res), do: Slice.get_error_reason(res) |> maybe_ignore()

  defp maybe_ignore({:unique, val}), do: {:ignore, val}
  defp maybe_ignore(e_or_ok), do: e_or_ok
end
