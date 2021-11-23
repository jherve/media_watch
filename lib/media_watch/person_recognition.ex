defmodule MediaWatch.PersonRecognition do
  alias MediaWatch.Spacy

  @spec identify_persons(map) :: map | {:error, reason :: any()}
  def identify_persons(map) when is_map(map) do
    map
    |> Enum.reduce_while(%{}, fn
      {k, v}, acc ->
        case v |> identify_persons_() do
          {:ok, list} -> {:cont, acc |> Map.put(k, list)}
          e = {:error, _} -> {:halt, e}
        end
    end)
  end

  defp identify_persons_(string) when is_binary(string) do
    with {:ok, list} <- string |> Spacy.extract_entities(),
         do: {:ok, list |> Enum.filter(&(&1.label == "PER")) |> Enum.map(& &1.text)}
  end
end
