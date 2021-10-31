defmodule MediaWatch.Catalog.Item.LInterviewPolitiqueLCI do
  use MediaWatch.Catalog.Item
  alias MediaWatch.Snapshots.Snapshot
  alias MediaWatch.Parsing.Slice.OpenGraph
  @list_of_shows_selector ".topic-emission-extract-block"
  @show_selector "article.grid-blk__item"

  @impl MediaWatch.Parsing.Parsable
  def prune_snapshot(parsed, %Snapshot{type: :html}),
    do: {:ok, %{full: parsed |> Floki.filter_out(:comment)}}

  @impl MediaWatch.Parsing.Sliceable
  def into_list_of_slice_attrs(%ParsedSnapshot{
        data: %{"full" => data},
        snapshot: %{url: page_url, source: %{type: :web_index_page}}
      }) do
    page_url = page_url |> URI.parse()
    get_show_cards(data, page_url) ++ [%{open_graph: OpenGraph.get_list_of_attributes(data)}]
  end

  defp get_show_cards(parsed, page_url) do
    parsed
    |> Floki.find(@list_of_shows_selector)
    |> Floki.find(@show_selector)
    |> Enum.map(fn item ->
      link = item |> get_link(page_url)

      %{
        html_preview_card: %{
          date: item |> get_date,
          title: item |> get_title,
          link: link,
          type: get_type(link)
        }
      }
    end)
  end

  defp get_date(item), do: item |> Floki.attribute("time", "datetime") |> List.first()
  defp get_title(item), do: item |> Floki.find("h2") |> Floki.text()

  defp get_link(item, page_url = %URI{}) do
    path = item |> Floki.attribute("a", "href") |> List.first()
    page_url |> URI.merge(path) |> URI.to_string()
  end

  defp get_type(link) do
    case link |> URI.parse() |> Map.get(:path) do
      "/replay-lci" <> _ -> :replay
      _ -> :article
    end
  end
end
