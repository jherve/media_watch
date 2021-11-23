defmodule MediaWatchInventory.Layout.LCI do
  alias MediaWatch.Snapshots.Snapshot
  alias MediaWatch.Parsing.ParsedSnapshot
  alias MediaWatch.Parsing.Slice.OpenGraph
  alias __MODULE__

  @doc "Return the type of preview from the link contained in the slice"
  @callback get_type_from_link(binary()) :: atom()

  @list_of_shows_selector ".topic-emission-extract-block"
  @show_selector "article.grid-blk__item"

  def prune_snapshot(parsed, %Snapshot{type: :html}),
    do: {:ok, %{full: parsed |> Floki.filter_out(:comment)}}

  def into_list_of_slice_attrs(
        %ParsedSnapshot{
          data: %{"full" => data},
          snapshot: %{url: page_url, source: %{type: :web_index_page}}
        },
        lci
      ) do
    page_url = page_url |> URI.parse()
    get_show_cards(data, page_url, lci) ++ [%{open_graph: OpenGraph.get_list_of_attributes(data)}]
  end

  defp get_show_cards(parsed, page_url, lci) do
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
          type: lci.get_type_from_link(link)
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

  def get_slice_kind(%{html_preview_card: %{link: link}}, lci), do: lci.get_type_from_link(link)
  def get_slice_kind(_, _), do: nil

  defmacro __using__(opts) do
    quote bind_quoted: [opts: opts] do
      @behaviour LCI

      @impl MediaWatch.Parsing.Parsable
      defdelegate prune_snapshot(parsed, snap), to: LCI

      @impl MediaWatch.Parsing.Sliceable
      def into_list_of_slice_attrs(parsed), do: LCI.into_list_of_slice_attrs(parsed, __MODULE__)

      @impl MediaWatch.Parsing.Sliceable
      def get_slice_kind(slice), do: LCI.get_slice_kind(slice, __MODULE__)
    end
  end
end
