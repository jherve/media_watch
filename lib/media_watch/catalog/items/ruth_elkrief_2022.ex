defmodule MediaWatch.Catalog.Item.RuthElkrief2022 do
  use MediaWatch.Catalog.Item
  use MediaWatch.Catalog.Item.Layout.LCI

  @impl MediaWatch.Analysis.Recognisable
  def in_entities_blacklist?(label), do: label in ["Ruth", "Pol.", "Pol", "PoL."]

  @impl MediaWatch.Catalog.Item.Layout.LCI
  def get_type_from_link(link) do
    case link |> URI.parse() |> Map.get(:path) do
      "/replay-lci/video-ruth-elkrief" <> _ -> :replay
      "/replay-lci/" <> _ -> :excerpt
      _ -> :article
    end
  end
end
