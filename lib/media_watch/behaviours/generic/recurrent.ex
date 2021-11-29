defmodule MediaWatch.Analysis.Recurrent.Generic do
  defmacro __using__(opts) do
    quote bind_quoted: [opts: opts] do
      @airing_schedule opts[:airing_schedule] ||
                         raise("`airing_schedule` not set in #{inspect(opts)}")
      @duration opts[:duration_minutes] * 60 ||
                  raise("duration_minutes` not set in #{inspect(opts)}")
      @time_zone opts[:timezone] || MediaWatch.DateTime.default_tz()

      alias MediaWatch.Analysis.Recurrent
      @behaviour Recurrent

      @impl Recurrent
      def get_airing_schedule(), do: @airing_schedule |> Crontab.CronExpression.Parser.parse!()

      @impl Recurrent
      def get_duration(), do: @duration

      @impl Recurrent
      def get_time_zone(), do: @time_zone |> Timex.Timezone.get()
    end
  end
end
