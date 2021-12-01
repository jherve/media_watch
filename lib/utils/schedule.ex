defmodule MediaWatch.Schedule do
  alias Crontab.{CronExpression, Scheduler}
  alias MediaWatch.DateTime, as: MyDateTime

  defguardp has_only_weekdays(cron)
            when is_struct(cron, CronExpression) and cron.day == [:*] and cron.month == [:*] and
                   cron.year == [:*]

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

  def to_string(cron = %CronExpression{}, locale \\ "fr"),
    do: "#{days_string(cron, locale)}, à #{time_string(cron, locale)}"

  def time_string(%CronExpression{hour: [hour], minute: [minute]}, locale),
    do:
      Time.new!(hour, minute, 0)
      |> MediaWatch.Cldr.Time.to_string!(format: :short, locale: locale)

  def days_string(c = %CronExpression{weekday: [{:-, 1, 5}]}, "fr") when has_only_weekdays(c),
    do: "du lundi au vendredi"

  def days_string(c = %CronExpression{weekday: [{:-, 1, 4}]}, "fr") when has_only_weekdays(c),
    do: "du lundi au jeudi"

  def days_string(c = %CronExpression{weekday: [:*]}, "fr") when has_only_weekdays(c),
    do: "tous les jours"

  def days_string(c = %CronExpression{weekday: [{:-, 6, 7}]}, "fr") when has_only_weekdays(c),
    do: "le weekend"

  def days_string(c = %CronExpression{weekday: [6]}, "fr") when has_only_weekdays(c),
    do: "le samedi"

  def days_string(c = %CronExpression{weekday: [7]}, "fr") when has_only_weekdays(c),
    do: "le dimanche"
end
