defmodule MediaWatch.Catalog.Item.LInterviewPolitiqueLCI do
  use MediaWatch.Catalog.Item
  alias MediaWatch.Snapshots.Snapshot
  @header_selector "header.topic-milestone-blk"
  @list_of_shows_selector ".topic-emission-extract-block"
  @show_selector "article.grid-blk__item"
  @header_container_selector ".topic-milestone-blk__content-container"
  @header_description_selector ".topic-milestone-blk__content-subtitle"

  @impl MediaWatch.Parsing.Parsable
  def prune_snapshot(parsed, %Snapshot{type: :html}),
    do: {:ok, %{full: parsed |> Floki.filter_out(:comment)}}

  @impl MediaWatch.Parsing.Sliceable
  def into_list_of_slice_attrs(%ParsedSnapshot{
        data: %{"full" => data},
        snapshot: %{source: %{type: :web_index_page}}
      }),
      do: get_html_entries(data) ++ [get_html_header(data)]

  defp get_html_entries(parsed) do
    parsed
    |> Floki.find(@list_of_shows_selector)
    |> Floki.find(@show_selector)
    |> Enum.map(
      &%{html_list_item: %{date: &1 |> get_date, title: &1 |> get_title, link: &1 |> get_link}}
    )
  end

  defp get_date(item), do: item |> Floki.attribute("time", "datetime") |> List.first()
  defp get_title(item), do: item |> Floki.find("h2") |> Floki.text()
  defp get_link(item), do: item |> Floki.attribute("a", "href") |> List.first()

  defp get_html_header(parsed) do
    header =
      parsed
      |> Floki.find(@header_selector)
      |> Floki.find(@header_container_selector)

    %{
      html_header: %{
        image: %{url: get_header_image(header)},
        title: get_header_title(header),
        description: get_header_description(header)
      }
    }
  end

  defp get_header_title(parsed), do: parsed |> Floki.find("h1") |> Floki.text()

  defp get_header_description(parsed),
    do: parsed |> Floki.find(@header_description_selector) |> Floki.text()

  defp get_header_image(parsed), do: parsed |> Floki.attribute("img", "src") |> List.first()
end
