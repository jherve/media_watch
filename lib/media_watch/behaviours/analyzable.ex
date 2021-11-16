defmodule MediaWatch.Analysis.Analyzable do
  alias MediaWatch.Parsing.Slice

  @type slice_type() ::
          :item_description | :show_occurrence_description | :show_occurrence_excerpt

  @callback classify(Slice.t()) :: slice_type()
end
