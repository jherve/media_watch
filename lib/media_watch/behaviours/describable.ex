defmodule MediaWatch.Analysis.Describable do
  @callback get_description_attrs(integer(), MediaWatch.Parsing.Slice.t()) :: map()
end
