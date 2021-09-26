defmodule MediaWatch.Catalog.Channel.RTL do
  use MediaWatch.Catalog.Channel

  @impl true
  def get_name(), do: "RTL"
  @impl true
  def get_url(), do: "https://www.rtl.fr"
end
