defmodule MediaWatch.Analysis.ItemDescriptionServer do
  use MediaWatch.AsyncGenServer
  alias MediaWatch.{Analysis, Telemetry, Repo}
  alias MediaWatch.Analysis.Description
  @name __MODULE__
  @prefix [:media_watch, :item_description_server]

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: @name)
  end

  def do_description(item_id, slice, slice_type, module),
    do:
      fn ->
        GenServer.call(@name, {:do_description, item_id, slice, slice_type, module}, :infinity)
      end
      |> Telemetry.span_function_call(@prefix ++ [:do_description], %{module: module})

  @impl true
  def init([]), do: {:ok, AsyncGenServer.init_state()}

  @impl true
  def handle_call({:do_description, item_id, slice, slice_type, module}, pid, state) do
    fn ->
      result =
        with ok = {:ok, %Description{item_id: id}} <-
               Analysis.create_description(item_id, slice, module),
             {:ok, _} <- Analysis.create_slice_usage(slice.id, id, slice_type),
             do: ok

      {pid, result}
    end
    |> Repo.rescue_if_busy({pid, {:error, :database_busy}})
    |> AsyncGenServer.start_async_task(state)
  end

  @impl true
  def handle_task_end(_, {_, {:error, :database_busy}}, state), do: {:retry, state}

  def handle_task_end(_, {pid, e = {:error, _}}, state) do
    GenServer.reply(pid, e)
    {:remove, state}
  end

  def handle_task_end(_, {pid, ok = {:ok, _desc}}, state) do
    GenServer.reply(pid, ok)
    {:remove, state}
  end
end
