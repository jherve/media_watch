defmodule MediaWatch.Parsing.Sliceable do
  @callback slice(MediaWatch.Parsing.ParsedSnapshot.t()) :: [Ecto.Changeset.t()]
  @callback into_slice_cs(map(), MediaWatch.Parsing.ParsedSnapshot.t()) :: Ecto.Changeset.t()
end
