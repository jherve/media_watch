defmodule MediaWatch.Catalog.Channel.FranceInter do
  use MediaWatch.Catalog.CatalogableChannel

  def get_name(), do: "France Inter"
  def get_url(), do: "https://www.franceinter.fr"
end
