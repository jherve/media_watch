defmodule MediaWatch.Analysis.Analyzable do
  @type slice_type() ::
          :item_description | :show_occurrence_description | :show_occurrence_excerpt

  @callback classify(MediaWatch.Parsing.Slice.t()) :: slice_type()
end
