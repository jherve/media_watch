defmodule MediaWatch.Analysis.Hosted.Generic do
  defmacro __using__(opts) do
    quote bind_quoted: [opts: opts] do
      @hosts opts[:host_names] || raise("`host_names` not set in #{inspect(opts)}")
      @alternate_hosts opts[:alternate_hosts]
      @columnists opts[:columnists]

      alias MediaWatch.Analysis.Hosted

      @impl Hosted
      def get_hosts(), do: @hosts

      if @alternate_hosts do
        @impl Hosted
        def get_alternate_hosts(), do: @alternate_hosts
      end

      if @columnists do
        @impl Hosted
        def get_columnists(), do: @columnists
      end
    end
  end
end
