defmodule MediaWatch.Fuzzy do
  @moduledoc "A thin wrapper above Seqfuzz, that handles strings with diacritics."
  alias MediaWatch.Unicode

  @doc """
  A wrapper above `Seqfuzz.filter/3`

  This function adds a specific step when `pattern` contains diacritics. and
  ensures that looking e.g. for `"amelie"` will correctly match with `"Amélie"`, which
  the basic function does not always do.
  """
  def filter(enumerable, pattern, string_callback \\ & &1)

  def filter(enumerable, pattern, string_callback),
    do: filter(enumerable, pattern, string_callback, Unicode.has_diacritics?(pattern))

  defp filter(enumerable, pattern, string_callback, false) do
    pattern = pattern |> Unicode.remove_diacritics()

    enumerable
    |> Enum.map(&{&1, &1 |> string_callback.() |> Unicode.remove_diacritics()})
    |> Seqfuzz.filter(pattern, &(&1 |> elem(1)))
    |> Enum.map(&(&1 |> elem(0)))
  end

  defp filter(enumerable, pattern, string_callback, true),
    do: Seqfuzz.filter(enumerable, pattern, string_callback)
end
