defmodule MediaWatch.Catalog.Item.Le8h30FranceInfo do
  use MediaWatch.Catalog.ItemWorker,
    show: %{
      name: "8h30 franceinfo",
      url: "https://www.francetvinfo.fr/replay-radio/8h30-fauvelle-dely/",
      airing_schedule: "30 8 * * *",
      duration_minutes: 25
    },
    sources: [%{rss_feed: %{url: "https://radiofrance-podcast.net/podcast09/rss_16370.xml"}}],
    channels: [MediaWatch.Catalog.Channel.FranceInfo]

  @scan_title ~r/^.*\"8h30 franceinfo\" (de |d'|avec )(?P<guests>.*)$/
  @split_words ["et", "avec", "face à"] |> Enum.map(&" #{&1} ")

  @impl MediaWatch.Analysis.Recognisable
  def get_guests_attrs(occ = %{title: title}) do
    with %{"guests" => guests} <- Regex.named_captures(@scan_title, title) do
      guests |> to_list_of_names |> Enum.map(&%{person: %{label: &1}})
    else
      nil -> []
    end
  end

  defp to_list_of_names(guests_str) when is_binary(guests_str),
    do: guests_str |> String.split(@split_words) |> Enum.map(&String.trim/1)
end
