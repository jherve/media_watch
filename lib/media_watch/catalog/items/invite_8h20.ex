defmodule MediaWatch.Catalog.Item.Invite8h20 do
  use MediaWatch.Catalog.Item

  @impl MediaWatch.Analysis.Recognisable
  def in_entities_blacklist?(label), do: label in ["Grand", "Grand Entretien"]
end
