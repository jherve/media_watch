defmodule MediaWatch.DateTime do
  @max "9999-12-31 23:59:59" |> Timex.parse!("{ISO:Extended}")
  @min Timex.zero() |> Timex.to_datetime()

  def max(), do: @max
  def min(), do: @min

  def add_day(date, days \\ 1) do
    duration = days |> Timex.Duration.from_days()
    date |> Timex.add(duration) |> Timex.to_date()
  end

  def get_start_of_day(dt), do: dt |> Timex.to_date() |> Timex.to_datetime()
  def get_end_of_day(dt), do: dt |> get_start_of_day() |> add_day |> Timex.to_datetime()
end
