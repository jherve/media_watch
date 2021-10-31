defmodule MediaWatch.Catalog.Item.CAVous do
  use MediaWatch.Catalog.Item
  alias MediaWatch.Snapshots.Snapshot
  @list_of_shows_selector "[id^=season_france-5_c-a-vous] > ul"
  @show_selector "li"
  @title_selector ".c-card-video__textarea-subtitle"
  @date_selector ".c-metadata"
  @header_description_selector ".c-program-content__description"
  @header_image_selector "img.c-page-background__img"

  @impl MediaWatch.Parsing.Parsable
  def prune_snapshot(parsed, %Snapshot{type: :html}),
    do: {:ok, %{full: parsed}}

  @impl MediaWatch.Parsing.Sliceable
  def into_list_of_slice_attrs(%ParsedSnapshot{
        data: %{"full" => data},
        snapshot: %{url: page_url, source: %{type: :web_index_page}}
      }) do
    page_url = page_url |> URI.parse()
    [get_html_header(data)] ++ get_html_entries(data, page_url)
  end

  defp get_html_entries(parsed, page_url),
    do:
      parsed
      |> Floki.find(@list_of_shows_selector)
      |> Floki.find(@show_selector)
      |> Enum.map(
        &%{
          html_list_item: %{
            date: &1 |> get_date,
            title: &1 |> get_title,
            link: &1 |> get_link(page_url)
          }
        }
      )

  defp get_date(item),
    do:
      item
      |> Floki.find(@date_selector)
      |> List.first()
      |> Floki.text()
      |> String.trim()
      |> convert_date

  defp get_title(item), do: item |> Floki.find(@title_selector) |> Floki.text() |> String.trim()

  defp get_link(item, page_url = %URI{}) do
    path = item |> Floki.attribute("a", "href") |> List.first()
    page_url |> URI.merge(path) |> URI.to_string()
  end

  # TODO: Determining the correct year is a kind of magic in this version..
  # but it can be done from the "season's" number
  defp convert_date("diffusé le " <> date),
    do:
      with({:ok, date} <- date |> Timex.parse("{0D}/{0M}"), do: date |> Map.replace(:year, 2021))

  defp get_html_header(parsed),
    do: %{
      html_header: %{
        image: %{url: get_header_image(parsed)},
        title: get_header_title(parsed),
        description: get_header_description(parsed)
      }
    }

  defp get_header_title(parsed), do: parsed |> Floki.find("h1") |> Floki.text()

  defp get_header_description(parsed),
    do: parsed |> Floki.find(@header_description_selector) |> Floki.text()

  defp get_header_image(parsed),
    do: parsed |> Floki.attribute(@header_image_selector, "data-src") |> List.first()
end
