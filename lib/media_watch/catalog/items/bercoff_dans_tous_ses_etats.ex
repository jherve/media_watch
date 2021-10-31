defmodule MediaWatch.Catalog.Item.BercoffDansTousSesEtats do
  use MediaWatch.Catalog.Item
  alias MediaWatch.Parsing.Slice.OpenGraph

  @list_of_shows_selector "aside .col > ol"
  @show_selector "li > article.sud-show"

  @impl MediaWatch.Parsing.Parsable
  def prune_snapshot(parsed, %Snapshot{type: :html}),
    do: {:ok, %{full: parsed |> Floki.filter_out(:comment)}}

  @impl MediaWatch.Parsing.Sliceable
  def into_list_of_slice_attrs(%ParsedSnapshot{
        data: %{"full" => data},
        snapshot: %{source: %{type: :web_index_page}}
      }),
      do: get_show_cards(data) ++ [%{open_graph: OpenGraph.get_list_of_attributes(data)}]

  defp get_show_cards(parsed) do
    parsed
    |> Floki.find(@list_of_shows_selector)
    |> Floki.find(@show_selector)
    |> Enum.map(fn item ->
      link = item |> get_link()

      %{
        html_preview_card: %{
          date: item |> get_date,
          title: item |> get_title,
          link: link,
          type: :reference_page,
          text: item |> get_text
        }
      }
    end)
  end

  defp get_date(item),
    do:
      with(
        [date_str] <- item |> Floki.attribute("time", "datetime"),
        {:ok, date} <- date_str |> Timex.parse("{YYYY}-{0M}-{0D}"),
        do: date
      )

  defp get_title(item),
    do:
      item
      |> Floki.find(".sud-author")
      |> List.first()
      |> Floki.text()
      |> String.trim()
      |> String.replace(~r/\s+/, " ")

  defp get_link(item),
    do: item |> Floki.attribute("a.copy-link", "data-clipboard-text") |> List.first()

  defp get_text(item), do: item |> Floki.find("p") |> Floki.text()
end
