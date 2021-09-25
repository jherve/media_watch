defmodule MediaWatch.Analysis.Describable do
  @callback describe(any()) :: any()

  defmacro __using__(_opts) do
    quote do
      @behaviour MediaWatch.Analysis.Describable

      def describe(slice) do
        alias MediaWatch.Catalog
        alias MediaWatch.Analysis.Description

        item_id = Catalog.get_item_id(slice.source_id)
        Description.from(slice, item_id)
      end

      defoverridable describe: 1
    end
  end
end
