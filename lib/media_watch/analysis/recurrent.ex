defmodule MediaWatch.Analysis.Recurrent do
  @type time_slot() :: {start :: DateTime.t(), end_ :: DateTime.t()}

  @callback get_airing_schedule() :: Crontab.CronExpression.t()
  @callback get_time_zone() :: Timex.TimezoneInfo.t()
  @callback get_time_slot(DateTime.t()) :: time_slot()
  @callback get_airing_time(DateTime.t()) :: DateTime.t() | {:error, atom()}
  @callback get_occurrence_at(DateTime.t()) :: any()
  @callback get_occurrence_cs(MediaWatch.Parsing.Slice.t()) :: Ecto.Changeset.t()
  @callback get_occurrence_change_cs(
              MediaWatch.Analysis.ShowOccurrence.t(),
              used :: [MediaWatch.Parsing.Slice.t()],
              discarded :: [MediaWatch.Parsing.Slice.t()],
              new :: [MediaWatch.Parsing.Slice.t()]
            ) :: Ecto.Changeset.t()

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

      defp to_time_zone(dt), do: dt |> Timex.Timezone.convert(get_time_zone())
    end
  end
end
