defmodule MediaWatch.Analysis.Recurrent do
  @callback get_time_slot(DateTime.t()) :: {slot_start :: DateTime.t(), slot_end :: DateTime.t()}
  @callback get_occurrences_within_time_slot(DateTime.t()) :: [any()]
  @callback create_occurrence(any()) :: any()
  @callback create_occurrence_and_store(any(), Ecto.Repo.t()) :: any()
  @callback update_occurrence(any(), any()) :: any()
  @callback update_occurrence_and_store(any(), any(), Ecto.Repo.t()) :: any()

  defmacro __using__(_opts) do
    quote do
      @behaviour MediaWatch.Analysis.Recurrent

      @impl true
      def get_time_slot(dt),
        do: {MediaWatch.DateTime.get_start_of_day(dt), MediaWatch.DateTime.get_end_of_day(dt)}

      @impl true
      def create_occurrence_and_store(slice, repo),
        do:
          slice
          |> create_occurrence()
          |> MediaWatch.Repo.insert_and_retry(repo)
          |> annotate_if_same_time_slot()

      @impl true
      def update_occurrence_and_store(occ, slice, repo),
        do:
          occ
          |> update_occurrence(slice)
          |> MediaWatch.Repo.update_and_retry(repo)

      defp annotate_if_same_time_slot(
             {:error,
              cs = %{
                errors: [
                  date_start: {_, [validation: :unsafe_unique_time_slot, occurrences: [occ]]}
                ]
              }}
           ),
           do: {:error, {:same_time_slot, occ}}

      defp annotate_if_same_time_slot(res), do: res

      defoverridable create_occurrence_and_store: 2
    end
  end
end
