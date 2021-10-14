defmodule MediaWatch.Parsing.Sliceable do
  @callback slice(MediaWatch.Parsing.ParsedSnapshot.t()) :: [Ecto.Changeset.t()]
  @callback into_slice_cs(map(), MediaWatch.Parsing.ParsedSnapshot.t()) :: Ecto.Changeset.t()
  @callback slice_and_insert(MediaWatch.Parsing.ParsedSnapshot.t(), Ecto.Repo.t()) ::
              {:ok, ok_res :: list(), unique_res :: list()}
              | {:error, ok_res :: list(), unique_res :: list(), error_res :: list()}
end
