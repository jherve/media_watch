defmodule MediaWatch.Analysis.Describable do
  @callback create_description(any()) :: any()
end
