defmodule MediaWatchInventory.Item.RuthElkrief2022 do
  use MediaWatchInventory.Item
  use MediaWatchInventory.Layout.LCI

  @impl MediaWatch.Analysis.Recognisable
  def in_entities_blacklist?(label), do: label in ["Ruth", "Pol.", "Pol", "PoL."]

  @impl MediaWatchInventory.Layout.LCI
  def get_type_from_link(link) do
    case link |> URI.parse() |> Map.get(:path) do
      "/replay-lci/video-ruth-elkrief" <> _ -> :replay
      "/replay-lci/" <> _ -> :excerpt
      _ -> :article
    end
  end
end
