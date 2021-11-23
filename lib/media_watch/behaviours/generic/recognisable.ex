defmodule MediaWatch.Analysis.Recognisable.Generic do
  @behaviour MediaWatch.Analysis.Recognisable
  alias MediaWatch.PersonRecognition
  alias MediaWatch.Parsing.Slice
  alias MediaWatch.Analysis.{Hosted, ShowOccurrence, EntitiesClassification}

  def get_entities_attrs(%Slice{
        type: :rss_channel_description,
        rss_channel_description: %{title: title, description: desc}
      }),
      do: get_entities_attrs(title, desc)

  def get_entities_attrs(%Slice{type: :rss_entry, rss_entry: %{title: title, description: desc}}),
    do: get_entities_attrs(title, desc)

  def get_entities_attrs(%Slice{
        type: :html_preview_card,
        html_preview_card: %{title: title, text: desc}
      }),
      do: get_entities_attrs(title, desc || "")

  def get_entities_attrs(%Slice{type: :open_graph, open_graph: %{title: title, description: desc}}),
      do: get_entities_attrs(title, desc || "")

  defp get_entities_attrs(title, desc),
    do:
      %{title: title, description: desc}
      |> PersonRecognition.identify_persons()
      |> Enum.flat_map(fn {k, v} -> v |> into_attrs_list(k |> Atom.to_string()) end)

  defp into_attrs_list(name_list, location_in_slice) when is_list(name_list),
    do:
      name_list
      |> Enum.uniq()
      |> Enum.map(&%{type: "PER", label: &1, location_in_slice: location_in_slice})

  def get_guests_attrs(list, hosted) when is_list(list),
    do: list |> Enum.map(&get_guests_attrs(&1, hosted))

  def get_guests_attrs(%ShowOccurrence{slices: slices}, hosted) do
    entities =
      slices |> organize_entities |> EntitiesClassification.cleanup() |> reject_hosts(hosted)

    entities
    |> EntitiesClassification.get_guests()
    |> EntitiesClassification.pick_candidates()
    |> Enum.map(&%{person: %{label: &1}})
  end

  defp organize_entities(slices),
    do:
      slices
      |> Enum.flat_map(fn %{entities: entities, type: type, kind: kind} ->
        entities |> Enum.map(&%{label: &1.label, type: {type, kind}, field: &1.location_in_slice})
      end)

  defp reject_hosts(entities, hosted) do
    hosts = Hosted.get_all_hosts(hosted)
    # The entities recognition service only returns names that do not have any hyphens
    # (e.g. "Jean-Pierre X" is spelled "Jean Pierre X"), but we chose to store hosts
    # using the correct spelling, with hyphens.
    hosts_unhyphenated = hosts |> Enum.map(&(&1 |> String.replace("-", " ")))
    entities |> Enum.reject(&(&1.label in (hosts ++ hosts_unhyphenated)))
  end

  defmacro __using__(_opts) do
    quote do
      alias MediaWatch.Analysis.Recognisable
      @behaviour Recognisable

      @impl Recognisable
      defdelegate get_guests_attrs(occ, hosted), to: Recognisable.Generic

      @impl Recognisable
      defdelegate get_entities_attrs(slice), to: Recognisable.Generic

      defoverridable get_guests_attrs: 2
    end
  end
end
