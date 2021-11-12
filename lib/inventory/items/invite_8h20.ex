defmodule MediaWatchInventory.Item.Invite8h20 do
  use MediaWatchInventory.Item

  @impl MediaWatch.Analysis.Recognisable
  def in_entities_blacklist?(label), do: label in ["Grand", "Grand Entretien"]
end
