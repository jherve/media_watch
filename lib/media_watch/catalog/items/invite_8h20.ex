defmodule MediaWatch.Catalog.Item.Invite8h20 do
  use MediaWatch.Catalog.Item

  @scan_title ~r/^(?P<guests>.*) : ".*"$/
  @split_words ["et", "avec", "face à"] |> Enum.map(&" #{&1} ")

  @impl MediaWatch.Analysis.Recognisable
  def get_guests_attrs(%{detail: %{title: title, description: desc}}) do
    case guests_from_description(desc) do
      list when is_list(list) ->
        list |> Enum.map(&%{person: %{label: &1}})

      :error ->
        case guests_from_title(title) do
          list when is_list(list) -> list |> Enum.map(&%{person: %{label: &1}})
          :error -> []
        end
    end
  end

  @impl MediaWatch.Analysis.Recognisable
  def in_entities_blacklist?(label), do: label in ["Grand", "Grand Entretien"]

  defp guests_from_description(desc) do
    split = desc |> String.split(" - ") |> Enum.map(&String.trim/1)

    with full_str when not is_nil(full_str) <-
           split |> Enum.find(&(&1 |> String.starts_with?("invité"))),
         [_, guests_str] <- full_str |> String.split(":"),
         guests_str <- guests_str |> String.trim(),
         split_str <- guests_str |> String.split(",") do
      split_str
      |> Enum.map(fn str ->
        str |> String.split() |> Enum.map(&String.capitalize/1) |> Enum.join(" ")
      end)
    else
      nil -> :error
    end
  end

  defp guests_from_title(title) do
    with %{"guests" => guests} <- Regex.named_captures(@scan_title, title) do
      guests |> to_list_of_names
    else
      nil -> :error
    end
  end

  defp to_list_of_names(guests_str) when is_binary(guests_str),
    do: guests_str |> String.split(@split_words) |> Enum.map(&String.trim/1)
end
