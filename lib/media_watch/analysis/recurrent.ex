defmodule MediaWatch.Analysis.Recurrent do
  @callback format_occurrence(any()) :: any()
  @callback format_occurrence_and_insert(any(), Ecto.Repo.t()) :: any()

  defmacro __using__(_opts) do
    quote do
      @behaviour MediaWatch.Analysis.Recurrent

      @impl true
      def format_occurrence_and_insert(slice, repo),
        do: slice |> format_occurrence() |> MediaWatch.Repo.insert_and_retry(repo)

      defoverridable format_occurrence_and_insert: 2
    end
  end
end
