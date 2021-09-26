defmodule MediaWatch.Catalog.Channel.RMC do
  use MediaWatch.Catalog.CatalogableChannel

  def get_name(), do: "RMC"
  def get_url(), do: "https://rmc.bfmtv.com/"
end
