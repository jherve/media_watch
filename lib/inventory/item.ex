defmodule MediaWatchInventory.Item do
  defmacro __using__(_opts) do
    quote do
      @config Application.compile_env(:media_watch, MediaWatchInventory)[:items][__MODULE__] ||
                raise("Config for #{__MODULE__} should be set")

      @show @config[:show]

      @item_args (cond do
                    not is_nil(@show) -> %{show: @show}
                    true -> raise("At least one of [`show`] should be set")
                  end)

      @sources @config[:sources] || raise("`sources` should be set")
      @channels @config[:channels] || raise("`channels` should be set")

      use MediaWatch.Parsing.Parsable.Generic
      use MediaWatch.Parsing.Sliceable.Generic
      use MediaWatch.Analysis.Describable.Generic
      use MediaWatch.Analysis.Recognisable.Generic
      use MediaWatch.Analysis.Hosted.Generic, @show
      use MediaWatch.Analysis.Recurrent.Generic, @show

      import Ecto.Query
      alias MediaWatch.Repo
    end
  end
end
