defmodule MediaWatch.Telemetry do
  def span_function_call(fun, name, args \\ %{}) when is_function(fun, 0) do
    start = emit_start(name, args)

    result = fun.()
    emit_stop(name, args, start)

    result
  end

  defp emit_start(name, args) do
    start_time_mono = System.monotonic_time()

    :telemetry.execute(
      name ++ [:start],
      %{system_time: System.system_time()},
      args
    )

    start_time_mono
  end

  defp emit_stop(name, args, start_time) do
    duration = System.monotonic_time() - start_time

    :telemetry.execute(
      name ++ [:stop],
      %{duration: duration},
      args
    )
  end
end
