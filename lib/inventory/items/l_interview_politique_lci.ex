defmodule MediaWatchInventory.Item.LInterviewPolitiqueLCI do
  use MediaWatchInventory.Item
  use MediaWatchInventory.Layout.LCI

  @impl MediaWatchInventory.Layout.LCI
  def get_type_from_link(link) do
    case link |> URI.parse() |> Map.get(:path) do
      "/replay-lci" <> _ -> :replay
      _ -> nil
    end
  end
end
