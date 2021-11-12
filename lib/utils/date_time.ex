defmodule MediaWatch.DateTime do
  @max "9999-12-31 23:59:59" |> Timex.parse!("{ISO:Extended}")
  @min Timex.zero() |> Timex.to_datetime()

  def max(), do: @max
  def min(), do: @min

  def to_string(date = %Date{}, locale \\ "fr"),
    do: MediaWatch.Cldr.Date.to_string!(date, format: "EEEE d MMMM y", locale: locale)
end
