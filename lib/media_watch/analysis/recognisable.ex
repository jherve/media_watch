defmodule MediaWatch.Analysis.Recognisable do
  @doc "Get a list of maps of persons' attributes from a show occurrence"
  @callback get_guests_attrs(MediaWatch.Analysis.ShowOccurrence.t()) :: [map()]

  @optional_callbacks get_guests_attrs: 1
end
