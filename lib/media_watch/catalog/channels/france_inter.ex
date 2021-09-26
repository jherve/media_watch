defmodule MediaWatch.Catalog.Channel.FranceInter do
  use MediaWatch.Catalog.Channel

  @impl true
  def get_name(), do: "France Inter"
  @impl true
  def get_url(), do: "https://www.franceinter.fr"
end
