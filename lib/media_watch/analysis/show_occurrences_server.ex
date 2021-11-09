defmodule MediaWatch.Analysis.ShowOccurrencesServer do
  use MediaWatch.AsyncGenServer
  alias MediaWatch.{Analysis, Telemetry}
  alias MediaWatch.Analysis.ShowOccurrence
  @name __MODULE__
  @prefix [:media_watch, :show_occurrences_server]

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: @name)
  end

  def detect_occurrence(slice, show_id, slice_type, module),
    do:
      fn ->
        GenServer.call(@name, {:detect_occurrence, slice, show_id, slice_type, module}, :infinity)
      end
      |> Telemetry.span_function_call(@prefix ++ [:detect_occurrence], %{module: module})

  def add_details(occurrence, slice),
    do:
      fn -> GenServer.call(@name, {:add_details, occurrence, slice}, :infinity) end
      |> Telemetry.span_function_call(@prefix ++ [:add_details])

  def do_guest_detection(occurrence, module),
    do:
      fn -> GenServer.call(@name, {:do_guest_detection, occurrence, module}, :infinity) end
      |> Telemetry.span_function_call(@prefix ++ [:do_guest_detection], %{module: module})

  @impl true
  def init([]), do: {:ok, AsyncGenServer.init_state()}

  @impl true
  def handle_call({:detect_occurrence, slice, show_id, slice_type, module}, pid, state) do
    fn ->
      with {:ok, date} <- slice |> Analysis.extract_date(),
           time_slot <- date |> module.get_time_slot(),
           airing_time when is_struct(airing_time, DateTime) <- module.get_airing_time(date),
           ok = {:ok, %ShowOccurrence{id: id}} <-
             Analysis.create_occurrence(show_id, airing_time, time_slot),
           {:ok, _} <- Analysis.create_slice_usage(slice.id, id, slice_type) do
        GenServer.reply(pid, ok)
      else
        {:error, {:unique, occ}} -> GenServer.reply(pid, {:ok, occ})
        e = {:error, _} -> GenServer.reply(pid, e)
      end
    end
    |> AsyncGenServer.start_async_task(state)
  end

  def handle_call({:add_details, occurrence, slice}, pid, state) do
    fn ->
      case Analysis.create_occurrence_details(occurrence.id, slice) do
        ok = {:ok, _} ->
          GenServer.reply(pid, ok)

        {:error, {:unique, existing}} ->
          GenServer.reply(pid, Analysis.update_occurrence_details(existing, slice))

        e = {:error, _} ->
          GenServer.reply(pid, e)
      end
    end
    |> AsyncGenServer.start_async_task(state)
  end

  def handle_call({:do_guest_detection, occurrence, module}, pid, state) do
    fn ->
      guests =
        occurrence
        |> Analysis.insert_guests_from(module)
        |> Enum.filter(&match?({:ok, _}, &1))

      GenServer.reply(pid, guests)
    end
    |> AsyncGenServer.start_async_task(state)
  end
end
