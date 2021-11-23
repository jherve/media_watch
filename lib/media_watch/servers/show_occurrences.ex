defmodule MediaWatch.Analysis.ShowOccurrencesServer do
  use MediaWatch.AsyncGenServer
  alias MediaWatch.Telemetry

  alias MediaWatch.Analysis.{
    OccurrenceDetectionOperation,
    GuestDetectionOperation,
    OccurrenceDetailOperation
  }

  @name __MODULE__
  @prefix [:media_watch, :show_occurrences_server]

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: @name)
  end

  def detect_occurrence(slice, module),
    do:
      fn -> GenServer.call(@name, {:detect_occurrence, slice, module}, :infinity) end
      |> Telemetry.span_function_call(@prefix ++ [:detect_occurrence], %{module: module})

  def add_details(occurrence, slice),
    do:
      fn -> GenServer.call(@name, {:add_details, occurrence, slice}, :infinity) end
      |> Telemetry.span_function_call(@prefix ++ [:add_details])

  def do_guest_detection(occurrence, recognizable, hosted),
    do:
      fn ->
        GenServer.call(@name, {:do_guest_detection, occurrence, recognizable, hosted}, :infinity)
      end
      |> Telemetry.span_function_call(@prefix ++ [:do_guest_detection])

  @impl true
  def init([]),
    do: {:ok, AsyncGenServer.init_state(%{unmatched_slices: MapSet.new()})}

  @impl true
  def handle_call({operation = :detect_occurrence, slice, module}, pid, state) do
    fn -> {operation, pid, do_detect_occurrence(slice, module)} end
    |> AsyncGenServer.start_async_task(state, %{slice_id: slice.id})
  end

  def handle_call({operation = :add_details, occurrence, slice}, pid, state) do
    fn -> {operation, pid, do_add_details(occurrence, slice)} end
    |> AsyncGenServer.start_async_task(state)
  end

  def handle_call({operation = :do_guest_detection, occurrence, recognizable, hosted}, pid, state) do
    fn -> {operation, pid, do_guest_detection_(occurrence, recognizable, hosted)} end
    |> AsyncGenServer.start_async_task(state)
  end

  defp do_detect_occurrence(slice, module),
    do:
      OccurrenceDetectionOperation.new(slice, module)
      |> OccurrenceDetectionOperation.set_retry_strategy(fn :database_busy, _ -> :retry_exp end)
      |> OccurrenceDetectionOperation.run()

  defp do_add_details(occurrence, slice),
    do:
      OccurrenceDetailOperation.new(occurrence, slice)
      |> OccurrenceDetailOperation.set_retry_strategy(fn :database_busy, _ -> :retry_exp end)
      |> OccurrenceDetailOperation.run()

  defp do_guest_detection_(occurrence, recognizable, hosted),
    do:
      GuestDetectionOperation.new(occurrence, recognizable, hosted)
      |> GuestDetectionOperation.set_retry_strategy(fn :database_busy, _ -> :retry_exp end)
      |> GuestDetectionOperation.run()

  @impl true
  def handle_task_end(
        _,
        {:detect_occurrence, pid, result = {status, _}},
        %{slice_id: slice_id},
        state
      )
      when status in [:ok, :already] do
    GenServer.reply(pid, result)
    {:remove, update_in(state.unmatched_slices, &(&1 |> MapSet.delete(slice_id)))}
  end

  def handle_task_end(
        _,
        {:detect_occurrence, pid, result = {:error, _}},
        %{slice_id: slice_id},
        state
      ) do
    GenServer.reply(pid, result)
    {:remove, update_in(state.unmatched_slices, &(&1 |> MapSet.put(slice_id)))}
  end

  def handle_task_end(_, {:do_guest_detection, pid, guests}, _, state) do
    GenServer.reply(pid, guests)
    {:remove, state}
  end

  def handle_task_end(_, {:add_details, pid, result}, _, state) do
    GenServer.reply(pid, result)
    {:remove, state}
  end
end
