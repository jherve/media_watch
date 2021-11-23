defmodule MediaWatch.Analysis.Recognisable do
  alias MediaWatch.Analysis.EntityRecognized

  @doc "Extract a list of entities attributes from a slice"
  @callback get_entities_attrs(MediaWatch.Parsing.Slice.t()) :: [map]

  @doc "Return a list of the persons to blacklist from the entities recognition"
  @callback in_entities_blacklist?(binary()) :: boolean()

  @doc "Get a list of maps of persons' attributes from a show occurrence"
  @callback get_guests_attrs(MediaWatch.Analysis.ShowOccurrence.t(), hosted_module :: atom()) :: [
              map()
            ]

  @optional_callbacks in_entities_blacklist?: 1

  def get_entities_cs!(slice, module),
    do:
      module.get_entities_attrs(slice)
      |> Enum.map(&EntityRecognized.changeset(%EntityRecognized{slice: slice}, &1))
end
