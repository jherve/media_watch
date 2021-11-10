defmodule MediaWatch.Analysis.EntityRecognitionServer do
  use MediaWatch.AsyncGenServer
  alias MediaWatch.{Analysis, Telemetry, Repo}
  alias MediaWatch.Parsing.Slice
  @name __MODULE__
  @prefix [:media_watch, :entity_recognition_server]

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: @name)
  end

  def recognize_entities(slice, module),
    do:
      fn -> GenServer.call(@name, {:do_entity_recognition, slice, module}, :infinity) end
      |> Telemetry.span_function_call(@prefix ++ [:recognize_entities], %{module: module})

  @impl true
  def init([]), do: {:ok, AsyncGenServer.init_state()}

  @impl true
  def handle_call({:do_entity_recognition, slice = %Slice{}, module}, pid, state) do
    fn -> {pid, slice |> Analysis.insert_entities_from(module)} end
    |> Repo.rescue_if_busy({pid, {:error, :database_busy}})
    |> AsyncGenServer.start_async_task(state)
  end

  @impl true
  def handle_task_end(_, {_, {:error, :database_busy}}, state), do: {:retry, state}

  def handle_task_end(_, {pid, {:error, _}}, state) do
    GenServer.reply(pid, [])
    {:remove, state}
  end

  def handle_task_end(_, {pid, list}, state) when is_list(list) do
    GenServer.reply(pid, list |> Enum.filter(&match?({:ok, _}, &1)) |> Enum.map(&elem(&1, 1)))
    {:remove, state}
  end
end
