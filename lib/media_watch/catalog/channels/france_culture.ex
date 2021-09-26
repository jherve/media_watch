defmodule MediaWatch.Catalog.Channel.FranceCulture do
  use MediaWatch.Catalog.Channel

  @impl true
  def get_name(), do: "France Culture"

  @impl true
  def get_url(), do: "https://www.franceculture.fr"
end
