defmodule MediaWatch.Analysis.Recurrent do
  @callback format_occurrence(any()) :: any()

  defmacro __using__(_opts) do
    quote do
      @behaviour MediaWatch.Analysis.Recurrent

      defdelegate format_occurrence(slice), to: MediaWatch.Analysis.Recurrent

      defoverridable format_occurrence: 1
    end
  end

  def format_occurrence(slice) do
    alias MediaWatch.Catalog
    alias MediaWatch.Analysis.ShowOccurrence

    show_id = Catalog.get_show_id(slice.source_id)
    ShowOccurrence.from(slice, show_id)
  end
end
