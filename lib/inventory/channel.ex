defmodule MediaWatchInventory.Channel do
  defmacro __using__(_opts) do
    quote do
      import Ecto.Query
      alias MediaWatch.Repo

      @config Application.compile_env(:media_watch, MediaWatchInventory)[:channels][__MODULE__] ||
                raise("Config for #{__MODULE__} should be set")

      @name @config[:name] || raise("`name` should be set")
      @url @config[:url] || raise("`url` should be set")
    end
  end
end
