defmodule MediaWatch.Analysis.Recurrent do
  alias MediaWatch.Schedule

  @type time_slot() :: {start :: DateTime.t(), end_ :: DateTime.t()}

  @callback get_airing_schedule() :: Crontab.CronExpression.t()
  @callback get_time_zone() :: Timex.TimezoneInfo.t()
  @callback get_duration() :: duration_seconds :: integer()

  @spec get_airing_time(DateTime.t(), atom()) :: DateTime.t() | {:error, atom()}
  def get_airing_time(dt, recurrent) do
    dt_tz = dt |> MediaWatch.DateTime.into_tz(recurrent.get_time_zone())

    recurrent.get_airing_schedule()
    |> Schedule.get_airing_time(dt_tz)
  end
end
