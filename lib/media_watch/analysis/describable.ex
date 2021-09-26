defmodule MediaWatch.Analysis.Describable do
  @callback describe(any()) :: any()

  defmacro __using__(_opts) do
    quote do
      @behaviour MediaWatch.Analysis.Describable
    end
  end
end
