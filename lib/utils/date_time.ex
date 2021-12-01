defmodule MediaWatch.DateTime do
  alias Timex.Timezone

  @max "9999-12-31 23:59:59" |> Timex.parse!("{ISO:Extended}")
  @min Timex.zero() |> Timex.to_datetime()
  @default_tz "Europe/Paris"
  @one_day Timex.Duration.from_days(1)

  def max(), do: @max
  def min(), do: @min

  def to_string(date = %Date{}, locale \\ "fr"),
    do: MediaWatch.Cldr.Date.to_string!(date, format: "EEEE d MMMM y", locale: locale)

  def default_tz(), do: @default_tz
  def into_tz(dt, tz), do: dt |> Timex.Timezone.convert(tz)

  def extract_tz(dt), do: dt |> Timex.TimezoneInfo.from_datetime()

  def parse_date(string, pattern \\ "{YYYY}-{0M}-{0D}") when is_binary(string),
    do: string |> Timex.parse(pattern)

  def next_day(date = %Date{}), do: date |> Timex.add(@one_day) |> Timex.to_date()
  def previous_day(date = %Date{}), do: date |> Timex.subtract(@one_day) |> Timex.to_date()

  def into_day_slot(dt = %DateTime{}),
    do: {dt |> Timezone.beginning_of_day(), dt |> Timezone.end_of_day()}

  def into_day_slot(date = %Date{}, tz \\ @default_tz) do
    dt = date |> Timex.to_datetime(tz)
    dt |> into_day_slot()
  end

  def week_slot(dt = %DateTime{}),
    do: {dt |> Timex.beginning_of_week(), dt |> Timex.end_of_week()}

  def current_week_slot(), do: DateTime.utc_now() |> week_slot()

  def past_week_slot(),
    do: DateTime.utc_now() |> Timex.subtract(Timex.Duration.from_weeks(1)) |> week_slot()

  def month_slot(dt = %DateTime{}),
    do: {dt |> Timex.beginning_of_month(), dt |> Timex.end_of_month()}

  def current_month_slot(), do: DateTime.utc_now() |> month_slot()
  def last_month_slot(), do: DateTime.utc_now() |> Timex.shift(months: -1) |> month_slot()

  def to_month_name(_month_slot = {month_start, _}, locale \\ "fr"),
    do: month_start |> MediaWatch.Cldr.Date.to_string!(format: "LLLL", locale: locale)
end
