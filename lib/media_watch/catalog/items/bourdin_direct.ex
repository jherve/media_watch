defmodule MediaWatch.Catalog.Item.BourdinDirect do
  use MediaWatch.Catalog.ItemWorker,
    show: %{
      name: "Bourdin Direct",
      url: "https://rmc.bfmtv.com/emission/bourdin-direct/",
      airing_schedule: "35 8 * * MON-FRI",
      duration_minutes: 25
    },
    sources: [%{rss_feed: %{url: "https://podcast.rmc.fr/channel30/RMCInfochannel30.xml"}}],
    channels: [MediaWatch.Catalog.Channel.RMC]

  @scan_title ~r/.*:(?P<guests>.*)-.*/
  @split_words ["et", "avec", "face à"] |> Enum.map(&" #{&1} ")

  @impl MediaWatch.Analysis.Recognisable
  def get_guests_attrs(%{title: title}) do
    with %{"guests" => guests} <- Regex.named_captures(@scan_title, title) do
      guests |> to_list_of_names |> Enum.map(&%{person: %{label: &1}})
    else
      nil -> []
    end
  end

  defp to_list_of_names(guests_str) when is_binary(guests_str),
    do: guests_str |> String.split(@split_words) |> Enum.map(&String.trim/1)
end
