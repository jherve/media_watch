defmodule MediaWatch.Catalog.Channel.FranceInfo do
  use MediaWatch.Catalog.Channel

  @impl true
  def get_name(), do: "France Info"
  @impl true
  def get_url(), do: "https://www.francetvinfo.fr"
end
