defmodule MediaWatch.Catalog.Channel.RMC do
  use MediaWatch.Catalog.Channel

  @impl true
  def get_name(), do: "RMC"
  @impl true
  def get_url(), do: "https://rmc.bfmtv.com/"
end
