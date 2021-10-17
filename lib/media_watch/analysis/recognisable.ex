defmodule MediaWatch.Analysis.Recognisable do
  @doc "Get a list of entities changesets from a slice"
  @callback get_entities_cs(MediaWatch.Parsing.Slice.t()) :: [Ecto.Changeset.t()]

  @doc "Return a list of the persons to blacklist from the entities recognition"
  @callback in_entities_blacklist?(binary()) :: boolean()

  @doc "Get a list of maps of persons' attributes from a slice"
  @callback get_guests_attrs(MediaWatch.Parsing.Slice.t()) :: [map()]

  @optional_callbacks get_guests_attrs: 1, in_entities_blacklist?: 1
end
