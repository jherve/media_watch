defmodule MediaWatch.Parsing.Sliceable do
  alias MediaWatch.{Repo, RecoverableMulti}
  alias MediaWatch.Parsing.{ParsedSnapshot, Slice}

  @callback into_list_of_slice_attrs(ParsedSnapshot.t()) :: [map()]
  @callback into_slice_cs(map(), ParsedSnapshot.t()) :: Ecto.Changeset.t()

  def slice(parsed = %ParsedSnapshot{}, module),
    do:
      parsed
      |> module.into_list_of_slice_attrs()
      |> Enum.map(&module.into_slice_cs(&1, parsed))

  def slice_and_insert(snap, sliceable) do
    with cs_list when is_list(cs_list) <- slice(snap, sliceable),
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
