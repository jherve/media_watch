defmodule MediaWatchInventory do
  @config Application.compile_env(:media_watch, __MODULE__)

  def all_channel_modules(), do: @config[:channels] |> Keyword.keys()

  def all(), do: @config[:items] |> Keyword.keys()
end
