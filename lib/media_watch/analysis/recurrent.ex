defmodule MediaWatch.Analysis.Recurrent do
  @callback get_airing_schedule() :: Crontab.CronExpression.t()
  @callback get_time_zone() :: Timex.TimezoneInfo.t()
  @callback get_time_slot(DateTime.t()) :: {slot_start :: DateTime.t(), slot_end :: DateTime.t()}
  @callback get_airing_time(DateTime.t()) :: DateTime.t() | {:error, atom()}
  @callback get_occurrence_at(DateTime.t()) :: any()
  @callback create_occurrence(any()) :: any()
  @callback create_occurrence_and_store(any(), Ecto.Repo.t()) :: any()
  @callback update_occurrence(any(), any()) :: any()
  @callback update_occurrence_and_store(any(), any(), Ecto.Repo.t()) :: any()

  defmacro __using__(_opts) do
    quote do
      @behaviour MediaWatch.Analysis.Recurrent

      @impl true
      def get_time_slot(dt),
        do: get_airing_schedule() |> MediaWatch.Schedule.get_time_slot!(dt |> to_time_zone)

      @impl true
      def get_time_zone(), do: "Europe/Paris" |> Timex.Timezone.get()

      @impl true
      def get_airing_time(dt),
        do: get_airing_schedule() |> MediaWatch.Schedule.get_airing_time(dt |> to_time_zone)

      @impl true
      def create_occurrence_and_store(slice, repo),
        do:
          slice
          |> create_occurrence()
          |> MediaWatch.Repo.insert_and_retry(repo)
          |> explain_error()

      @impl true
      def update_occurrence_and_store(occ, slice, repo),
        do:
          occ
          |> repo.preload(:show)
          |> update_occurrence(slice)
          |> MediaWatch.Repo.update_and_retry(repo)

      defp to_time_zone(dt), do: dt |> Timex.Timezone.convert(get_time_zone())

      defp explain_error(
             {:error,
              cs = %{
                errors: [
                  show_id:
                    {_,
                     [
                       constraint: :unique,
                       constraint_name: "show_occurrences_show_id_airing_time_index"
                     ]}
                ]
              }}
           ) do
        with {_, airing_time} <- cs |> Ecto.Changeset.fetch_field(:airing_time),
             occ <- airing_time |> get_occurrence_at() do
          {:error, {:unique_airing_time, occ}}
        else
          _ -> {:error, :unique_airing_time}
        end
      end

      defp explain_error(
             {:error,
              cs = %{errors: [airing_time: {_, [type: :utc_datetime, validation: :cast]}]}}
           ),
           do: {:error, :no_airing_time_within_slot}

      defp explain_error(res), do: res

      defoverridable create_occurrence_and_store: 2
    end
  end
end
