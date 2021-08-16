defmodule MediaWatch.DateTime do
  @max "9999-12-31 23:59:59" |> Timex.parse!("{ISO:Extended}")
  @min Timex.zero() |> Timex.to_datetime()

  def max(), do: @max
  def min(), do: @min
end
