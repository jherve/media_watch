defmodule MediaWatch.Analysis.Recurrent do
  @callback format_occurrence(any()) :: any()

  defmacro __using__(_opts) do
    quote do
      @behaviour MediaWatch.Analysis.Recurrent
    end
  end
end
