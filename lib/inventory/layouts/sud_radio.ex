defmodule MediaWatchInventory.Layout.SudRadio do
  alias MediaWatch.DateTime
  alias MediaWatch.Snapshots.Snapshot
  alias MediaWatch.Parsing.ParsedSnapshot
  alias MediaWatch.Parsing.Slice.OpenGraph
  alias __MODULE__

  @list_of_shows_selector "aside .col > ol"
  @show_selector "li > article.sud-show"

  def prune_snapshot(parsed, %Snapshot{type: :html}),
    do: {:ok, %{full: parsed |> Floki.filter_out(:comment)}}

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
        {:ok, date} <- date_str |> DateTime.parse_date(),
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

  defmacro __using__(opts) do
    quote bind_quoted: [opts: opts] do
      @impl MediaWatch.Parsing.Parsable
      defdelegate prune_snapshot(parsed, snap), to: SudRadio

      @impl MediaWatch.Parsing.Sliceable
      defdelegate into_list_of_slice_attrs(parsed), to: SudRadio
    end
  end
end
