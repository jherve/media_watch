defmodule MediaWatch.Schedule do
  alias Crontab.{CronExpression, Scheduler}

  defguardp has_only_weekdays(cron)
            when is_struct(cron, CronExpression) and cron.day == [:*] and cron.month == [:*] and
                   cron.year == [:*]

  def get_airing_time(cron = %CronExpression{}, dt = %DateTime{time_zone: tz}) do
    with {:ok, prev_run} <- cron |> Scheduler.get_previous_run_date(dt |> DateTime.to_naive()),
         {:ok, dt} <- prev_run |> DateTime.from_naive(tz),
         do: dt
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
