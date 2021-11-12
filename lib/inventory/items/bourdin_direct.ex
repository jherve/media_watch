defmodule MediaWatchInventory.Item.BourdinDirect do
  use MediaWatchInventory.Item

  @impl MediaWatch.Analysis.Recognisable
  def in_entities_blacklist?(label), do: label in ["Bourdin Direct", "Apolline Matin", "Neumann"]
end
