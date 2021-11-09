defmodule MediaWatch.Analysis.EntityRecognitionServer do
  use MediaWatch.AsyncGenServer
  alias MediaWatch.{Analysis, Telemetry}
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
    fn ->
      entities =
        case slice |> Analysis.insert_entities_from(module) do
          # TODO: This effectively prevents any recovery or catchup on entity recognition, in the current state
          {:error, _} ->
            []

          list when is_list(list) ->
            list |> Enum.filter(&match?({:ok, _}, &1)) |> Enum.map(&elem(&1, 1))
        end

      GenServer.reply(pid, entities)
    end
    |> AsyncGenServer.start_async_task(state)
  end
end
