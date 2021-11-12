defmodule MediaWatch.Analysis.ShowOccurrencesServer do
  use MediaWatch.AsyncGenServer
  alias MediaWatch.{Analysis, Telemetry, Repo}
  alias MediaWatch.Analysis.{ShowOccurrence, Recurrent}
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
  def handle_call(
        {operation = :detect_occurrence, slice, show_id, slice_type, module},
        pid,
        state
      ) do
    fn ->
      result =
        with {:ok, date} <- slice |> Analysis.extract_date(),
             time_slot <- date |> Recurrent.get_time_slot(module),
             airing_time when is_struct(airing_time, DateTime) <-
               Recurrent.get_airing_time(date, module),
             ok = {:ok, %ShowOccurrence{id: id}} <-
               Analysis.create_occurrence(show_id, airing_time, time_slot),
             {:ok, _} <- Analysis.create_slice_usage(slice.id, id, slice_type) do
          ok
        else
          {:error, {:unique, occ}} -> {:ok, occ}
          e = {:error, _} -> e
        end

      {operation, pid, result}
    end
    |> Repo.rescue_if_busy({operation, pid, {:error, :database_busy}})
    |> AsyncGenServer.start_async_task(state, %{slice_id: slice.id})
  end

  def handle_call({operation = :add_details, occurrence, slice}, pid, state) do
    fn ->
      res =
        case Analysis.create_occurrence_details(occurrence.id, slice) do
          ok = {:ok, _} ->
            ok

          {:error, {:unique, existing}} ->
            Analysis.update_occurrence_details(existing, slice)

          e = {:error, _} ->
            e
        end

      {operation, pid, res}
    end
    |> Repo.rescue_if_busy({operation, pid, {:error, :database_busy}})
    |> AsyncGenServer.start_async_task(state)
  end

  def handle_call({operation = :do_guest_detection, occurrence, recognizable, hosted}, pid, state) do
    fn ->
      guests =
        occurrence
        |> Analysis.insert_guests_from(recognizable, hosted)
        |> Enum.filter(&match?({:ok, _}, &1))

      {operation, pid, guests}
    end
    |> Repo.rescue_if_busy({operation, pid, {:error, :database_busy}})
    |> AsyncGenServer.start_async_task(state)
  end

  @impl true
  def handle_task_end(_, {_, _, {:error, :database_busy}}, _, state), do: {:retry, state}

  def handle_task_end(
        _,
        {:detect_occurrence, pid, result = {:ok, _}},
        %{slice_id: slice_id},
        state
      ) do
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
