defmodule MediaWatch.Analysis.Describable do
  @callback create_description(any()) :: any()
  @callback create_description_and_store(any(), Ecto.Repo.t()) :: any()

  defmacro __using__(_opts) do
    quote do
      @behaviour MediaWatch.Analysis.Describable

      @impl true
      def create_description_and_store(slice, repo),
        do: slice |> create_description() |> MediaWatch.Repo.insert_and_retry(repo)

      defoverridable create_description_and_store: 2
    end
  end
end
