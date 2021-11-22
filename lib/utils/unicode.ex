defmodule MediaWatch.Unicode do
  @moduledoc "Handle Unicode-related transformations"

  @combining_diatrical_marks 0x0300..0x036F

  @spec has_diacritics?(binary()) :: boolean()
  def has_diacritics?(string) when is_binary(string),
    do: string |> :unicode.characters_to_nfd_list() |> Enum.any?(&is_diacritic?/1)

  @spec remove_diacritics(binary()) :: binary()
  def remove_diacritics(string) when is_binary(string),
    do:
      string
      |> :unicode.characters_to_nfd_list()
      |> Enum.reject(&is_diacritic?/1)
      |> List.to_string()

  defp is_diacritic?(character) when is_integer(character),
    do: character in @combining_diatrical_marks
end
