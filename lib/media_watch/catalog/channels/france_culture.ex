defmodule MediaWatch.Catalog.Channel.FranceCulture do
  use MediaWatch.Catalog.CatalogableChannel

  def get_name(), do: "France Culture"
  def get_url(), do: "https://www.franceculture.fr"
end
