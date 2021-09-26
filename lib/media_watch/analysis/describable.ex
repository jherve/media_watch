defmodule MediaWatch.Analysis.Describable do
  @callback describe(any()) :: any()
  @callback describe_and_insert(any(), Ecto.Repo.t()) :: any()

  defmacro __using__(_opts) do
    quote do
      @behaviour MediaWatch.Analysis.Describable

      def describe_and_insert(slice, repo), do: slice |> describe() |> repo.insert()

      defoverridable describe_and_insert: 2
    end
  end
end
