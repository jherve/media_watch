defmodule MediaWatch.Schedule do
  import Crontab.CronExpression
  alias Crontab.{CronExpression, Scheduler}
  alias Timex.{Timezone, TimezoneInfo}

  def get_time_slot!(
        %CronExpression{hour: [hour], minute: [minute], second: [second]},
        dt = %DateTime{}
      )
      when not is_tuple(hour) and not is_tuple(minute) and not is_tuple(second) do
    dt |> to_day_time_slot
  end

  def get_time_slot!(cron = %CronExpression{}, dt = %DateTime{}),
    do: raise("Can not figure out time slot from expression `#{inspect(cron)}`")

  def get_airing_time(cron = %CronExpression{}, dt = %DateTime{}) do
    tz = dt |> TimezoneInfo.from_datetime()

    with {start, end_} <- get_time_slot!(cron, dt),
         {:ok, next_run} <-
           cron |> Scheduler.get_next_run_date(start |> Timex.to_naive_datetime()),
         -1 <- Timex.compare(next_run, end_) do
      next_run |> Timex.to_datetime(tz)
    else
      1 -> {:error, :no_run_within_slot}
    end
  end

  defp to_day_time_slot(dt), do: {Timezone.beginning_of_day(dt), Timezone.end_of_day(dt)}
end
