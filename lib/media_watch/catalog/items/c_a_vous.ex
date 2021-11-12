defmodule MediaWatch.Catalog.Item.CAVous do
  use MediaWatch.Catalog.Item
  alias MediaWatch.Snapshots.Snapshot
  alias MediaWatch.Parsing.ParsedSnapshot
  alias MediaWatch.Parsing.Slice.OpenGraph
  @list_of_shows_selector "[id^=season_france-5_c-a-vous] > ul"
  @show_selector "li"
  @title_selector ".c-card-video__textarea-subtitle"
  @date_selector ".c-metadata"

  @impl MediaWatch.Parsing.Parsable
  def prune_snapshot(parsed, %Snapshot{type: :html}),
    do: {:ok, %{full: parsed}}

  @impl MediaWatch.Parsing.Sliceable
  def into_list_of_slice_attrs(%ParsedSnapshot{
        data: %{"full" => data},
        snapshot: %{url: page_url, source: %{type: :web_index_page}}
      }) do
    page_url = page_url |> URI.parse()
    [%{open_graph: OpenGraph.get_list_of_attributes(data)}] ++ get_replay_cards(data, page_url)
  end

  defp get_replay_cards(parsed, page_url),
    do:
      parsed
      |> Floki.find(@list_of_shows_selector)
      |> Floki.find(@show_selector)
      |> Enum.map(
        &%{
          html_preview_card: %{
            date: &1 |> get_date,
            title: &1 |> get_title,
            link: &1 |> get_link(page_url),
            type: :replay
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
end
