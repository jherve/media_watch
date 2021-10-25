defmodule MediaWatch.Catalog.Item.BourdinDirect do
  use MediaWatch.Catalog.Item

  @impl MediaWatch.Analysis.Recognisable
  def in_entities_blacklist?(label), do: label in ["Bourdin", "Estelle Midi", "Rothen", "Neumann"]
end
