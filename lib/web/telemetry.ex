defmodule MediaWatchWeb.Telemetry do
  use Supervisor
  import Telemetry.Metrics

  def start_link(arg) do
    Supervisor.start_link(__MODULE__, arg, name: __MODULE__)
  end

  @impl true
  def init(_arg) do
    children = [
      # Telemetry poller will execute the given period measurements
      # every 10_000ms. Learn more here: https://hexdocs.pm/telemetry_metrics
      {:telemetry_poller, measurements: periodic_measurements(), period: 10_000}
      # Add reporters as children of your supervision tree.
      # {Telemetry.Metrics.ConsoleReporter, metrics: metrics()}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  def metrics do
    [
      # Phoenix Metrics
      summary("phoenix.endpoint.stop.duration",
        unit: {:native, :millisecond}
      ),
      summary("phoenix.router_dispatch.stop.duration",
        tags: [:route],
        unit: {:native, :millisecond}
      ),

      # Database Metrics
      summary("media_watch.repo.query.total_time", unit: {:native, :millisecond}),
      summary("media_watch.repo.query.decode_time", unit: {:native, :millisecond}),
      summary("media_watch.repo.query.query_time", unit: {:native, :millisecond}),
      summary("media_watch.repo.query.queue_time", unit: {:native, :millisecond}),
      summary("media_watch.repo.query.idle_time", unit: {:native, :millisecond}),

      # HTTP Metric
      summary("finch.request.stop.duration", unit: {:native, :millisecond}),
      summary("finch.response.stop.duration", unit: {:native, :millisecond}, tags: [:host]),

      # VM Metrics
      summary("vm.memory.total", unit: {:byte, :kilobyte}),
      summary("vm.total_run_queue_lengths.total"),
      summary("vm.total_run_queue_lengths.cpu"),
      summary("vm.total_run_queue_lengths.io")
    ] ++ worker_metrics()
  end

  defp worker_metrics do
    [
      "snapshots_server.snapshot",
      "parsing_server.parse",
      "parsing_server.slice",
      "entity_recognition_server.recognize_entities",
      "show_occurrences_server.detect_occurrence",
      "show_occurrences_server.add_details",
      "show_occurrences_server.do_guest_detection",
      "item_description_server.do_description"
    ]
    |> Enum.map(
      &summary("media_watch.#{&1}.stop.duration",
        unit: {:native, :millisecond},
        reporter_options: [nav: :workers]
      )
    )
  end

  defp periodic_measurements do
    [
      # A module, function and arguments to be invoked periodically.
      # This function must call :telemetry.execute/3 and a metric must be added above.
      # {MediaWatchWeb, :count_users, []}
    ]
  end
end
