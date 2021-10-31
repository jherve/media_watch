defmodule MediaWatch.Catalog.Item.LInterviewPolitiqueLCI do
  use MediaWatch.Catalog.Item
  use MediaWatch.Catalog.Item.Layout.LCI

  @impl MediaWatch.Catalog.Item.Layout.LCI
  def get_type_from_link(link) do
    case link |> URI.parse() |> Map.get(:path) do
      "/replay-lci" <> _ -> :replay
      _ -> :article
    end
  end
end
