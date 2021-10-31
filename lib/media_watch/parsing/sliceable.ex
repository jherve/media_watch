defmodule MediaWatch.Parsing.Sliceable do
  @callback into_list_of_slice_attrs(MediaWatch.Parsing.ParsedSnapshot.t()) :: [map()]
  @callback into_slice_cs(map(), MediaWatch.Parsing.ParsedSnapshot.t()) :: Ecto.Changeset.t()
end
