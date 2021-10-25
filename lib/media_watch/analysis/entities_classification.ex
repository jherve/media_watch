defmodule MediaWatch.Analysis.EntitiesClassification do
  defguardp is_entity(e) when is_map(e) and is_map_key(e, :label)
  defguardp is_list_of_entities(list) when is_list(list) and (list == [] or is_entity(hd(list)))
  defguardp is_list_of_strings(list) when is_list(list) and (list == [] or is_binary(hd(list)))

  @doc """
  Do full cleanup on a list of strings.
  """
  def cleanup(list) when is_list_of_entities(list) or is_list_of_strings(list),
    do:
      list
      |> Enum.map(&trim_weird_characters/1)
      |> Enum.map(&capitalize_first_letters/1)
      |> split_names
      |> replace_missing_diacritics

  @doc """
  Capitalize only the first letter of a series of words
  """
  def capitalize_first_letters(string) when is_binary(string),
    do:
      string
      |> String.split(~r[-|\s], include_captures: true)
      |> Enum.map(&(&1 |> String.capitalize()))
      |> Enum.join("")

  def capitalize_first_letters(e) when is_entity(e),
    do: %{e | label: e.label |> capitalize_first_letters}

  @doc """
  Replace names by their counter-part that contains more diacritics within a list.
  """
  def replace_missing_diacritics(entities) when is_list_of_entities(entities) do
    rewrite_rule = entities |> Enum.map(& &1.label) |> get_diacritics_rewrite_map()

    entities
    |> Enum.map(fn e = %{label: label} ->
      down = label |> to_downcase_no_diacritics
      %{e | label: rewrite_rule |> Map.get(down)}
    end)
  end

  def replace_missing_diacritics(strings) when is_list_of_strings(strings) do
    rewrite_rule = get_diacritics_rewrite_map(strings)

    strings
    |> Enum.map(fn str ->
      down = str |> to_downcase_no_diacritics
      rewrite_rule |> Map.get(down)
    end)
  end

  defp get_diacritics_rewrite_map(strings) when is_list_of_strings(strings),
    do:
      strings
      |> Enum.map(
        &%{string: &1, down: &1 |> to_downcase_no_diacritics, length: &1 |> codepoint_length}
      )
      |> Enum.group_by(& &1.down, &(&1 |> Map.drop([:down])))
      |> Map.new(fn {k, v} ->
        {k, v |> Enum.sort_by(& &1.length, :desc) |> List.first() |> Map.get(:string)}
      end)

  defp to_downcase_no_diacritics(string) when is_binary(string),
    do:
      string
      |> :unicode.characters_to_nfd_binary()
      |> String.replace(~r/\W/u, "")
      |> String.downcase()

  defp codepoint_length(string) when is_binary(string),
    do:
      string
      |> :unicode.characters_to_nfd_binary()
      |> String.codepoints()
      |> length()

  @doc """
  Trim characters that do not belong in a name.

  Those characters are defined in the `@weird_characters` attribute.
  """
  @weird_characters ~S"\d-\s/"
  @trailing_weird_characters ~r/[#{@weird_characters}]*$/
  @leading_weird_characters ~r/^[#{@weird_characters}]*/

  def trim_weird_characters(string) when is_binary(string),
    do:
      string
      |> String.replace(@trailing_weird_characters, "")
      |> String.replace(@leading_weird_characters, "")

  def trim_weird_characters(e) when is_entity(e),
    do: %{e | label: e.label |> trim_weird_characters}

  @doc """
  Replace and split strings that are repetitions of others strings within a list.

  This excludes cases where the replacement would only have one word, as this likely
  means that a full name would be replaced by a single family name.

  e.g. `["Etienne Ollion Chercheur", "Etienne Ollion"]` becomes `["Etienne Ollion", "Etienne Ollion"]`
  but `["Bixente", "Bixente Lizarazu"]` stays `["Bixente", "Bixente Lizarazu"]`
  """
  def split_names(entities) when is_list_of_entities(entities) do
    rewrite = entities |> Enum.map(& &1.label) |> get_split_rewrite_map

    entities
    |> Enum.map(fn e = %{label: label} ->
      new_labels = rewrite |> Map.get(label) || [label]
      new_labels |> Enum.map(&%{e | label: &1})
    end)
    |> Enum.concat()
  end

  def split_names(strings) when is_list_of_strings(strings) do
    rewrite = get_split_rewrite_map(strings)

    strings |> Enum.map(&(rewrite |> Map.get(&1) || [&1])) |> Enum.concat()
  end

  defp get_split_rewrite_map(strings) when is_list_of_strings(strings),
    do:
      for(
        s <- strings,
        s2 <- strings,
        s != s2 and s2 |> has_more_than_one_word? and s |> String.contains?(s2),
        do: {s, s2}
      )
      |> Enum.group_by(&(&1 |> elem(0)), &(&1 |> elem(1)))

  defp has_more_than_one_word?(string), do: String.split(string, [" ", "-"]) |> length > 1

  @doc "Compute the score of a list of entities"
  def get_guests(entities) do
    get_initial_score_map(entities)
    |> update_score_by_freq(entities)
    |> update_score_by_most_freq_in_field(entities)
    |> update_score_by_present_in_several_fields(entities)
  end

  defp update_score_by_freq(score, entities),
    do:
      entities
      |> Enum.map(& &1.label)
      |> Enum.frequencies()
      |> Enum.reduce(score, fn {label, nb}, score -> score |> put_score(label, :by_freq, nb) end)

  defp update_score_by_most_freq_in_field(score, entities),
    do:
      entities
      |> group_by_and_drop(:type)
      |> group_by_and_drop(:field)
      |> sort_by_frequency
      |> take_while_top
      |> Map.values()
      |> Enum.flat_map(&Map.values/1)
      |> Enum.concat()
      |> Enum.map(fn {k, _} -> k.label end)
      |> Enum.frequencies()
      |> Enum.reduce(score, fn {label, nb}, score ->
        score |> put_score(label, :by_most_freq_in_field, nb)
      end)

  defp update_score_by_present_in_several_fields(score, entities),
    do:
      entities
      |> group_by_and_drop(:type)
      |> group_by_and_drop(:label)
      |> group_by_and_drop(:field)
      |> Map.values()
      |> Enum.map(&(&1 |> Enum.map(fn {k, v} -> {k, v |> Map.keys() |> Enum.count()} end)))
      |> Enum.map(&take_while_top/1)
      |> Enum.concat()
      |> Enum.reduce(score, fn {label, _}, score ->
        score |> put_score(label, :by_present_in_several_fields, 1)
      end)

  @doc "Extract guests from a map of score"
  def pick_candidates(score) when is_map(score) do
    score
    |> Enum.map(fn {k, v} -> {k, v |> Map.values() |> Enum.sum()} end)
    |> take_while_top
    |> Enum.map(&elem(&1, 0))
  end

  defp sort_by_frequency(list) when is_list(list),
    do: list |> Enum.frequencies() |> Enum.sort_by(fn {_, v} -> v end, :desc)

  defp sort_by_frequency(map) when is_map(map),
    do: map |> Map.new(fn {k, v} -> {k, v |> sort_by_frequency} end)

  defp take_while_top([]), do: []

  defp take_while_top(list) when is_list(list) do
    list = [{_, fst_count} | _] = list |> Enum.sort_by(fn {_val, count} -> count end, :desc)
    list |> Enum.take_while(fn {_val, count} -> count == fst_count end)
  end

  defp take_while_top(map) when is_map(map),
    do: map |> Map.new(fn {k, v} -> {k, v |> take_while_top} end)

  defp get_initial_score_map(entities),
    do: entities |> Enum.map(& &1.label) |> Enum.uniq() |> Map.new(&{&1, %{}})

  defp put_score(score_map, label, score_name, score_value),
    do: score_map |> Map.update!(label, &(&1 |> Map.put(score_name, score_value)))

  defp group_by_and_drop(list, key) when is_list(list),
    do: list |> Enum.group_by(&(&1 |> Map.get(key)), &(&1 |> Map.drop([key])))

  defp group_by_and_drop(map, key) when is_map(map),
    do: map |> Map.new(fn {k, v} -> {k, v |> group_by_and_drop(key)} end)
end
