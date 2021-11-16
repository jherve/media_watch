defmodule MediaWatch.Parsing.Sliceable do
  alias MediaWatch.Parsing.ParsedSnapshot

  @callback into_list_of_slice_attrs(ParsedSnapshot.t()) :: [map()]
  @callback into_slice_cs(map(), ParsedSnapshot.t()) :: Ecto.Changeset.t()

  def slice(parsed = %ParsedSnapshot{}, module),
    do:
      parsed
      |> module.into_list_of_slice_attrs()
      |> Enum.map(&module.into_slice_cs(&1, parsed))
end
