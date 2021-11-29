defmodule MediaWatch.Schedule do
  alias Crontab.{CronExpression, Scheduler}
  alias MediaWatch.DateTime, as: MyDateTime

  def get_time_slot!(
        %CronExpression{hour: [hour], minute: [minute], second: [second]},
        dt = %DateTime{}
      )
      when not is_tuple(hour) and not is_tuple(minute) and not is_tuple(second) do
    dt |> MyDateTime.into_day_slot()
  end

  def get_time_slot!(cron = %CronExpression{}, %DateTime{}),
    do: raise("Can not figure out time slot from expression `#{inspect(cron)}`")

  def get_airing_time(cron = %CronExpression{}, dt = %DateTime{}) do
    tz = dt |> MyDateTime.extract_tz()

    with {start, end_} <- get_time_slot!(cron, dt),
         {:ok, next_run} <-
           cron |> Scheduler.get_next_run_date(start |> Timex.to_naive_datetime()),
         -1 <- Timex.compare(next_run, end_) do
      next_run |> Timex.to_datetime(tz)
    else
      1 -> {:error, :no_run_within_slot}
    end
  end
end
