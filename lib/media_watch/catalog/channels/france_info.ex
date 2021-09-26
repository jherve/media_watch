defmodule MediaWatch.Catalog.Channel.FranceInfo do
  use MediaWatch.Catalog.CatalogableChannel

  def get_name(), do: "France Info"
  def get_url(), do: "https://www.francetvinfo.fr"
end
