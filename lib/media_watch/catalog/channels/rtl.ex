defmodule MediaWatch.Catalog.Channel.RTL do
  use MediaWatch.Catalog.CatalogableChannel

  def get_name(), do: "RTL"
  def get_url(), do: "https://www.rtl.fr"
end
