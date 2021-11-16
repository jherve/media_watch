defmodule MediaWatch.Analysis.ItemDescriptionServer do
  use MediaWatch.AsyncGenServer
  alias MediaWatch.Telemetry
  alias MediaWatch.Analysis.ItemDescriptionOperation
  @name __MODULE__
  @prefix [:media_watch, :item_description_server]

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: @name)
  end

  def do_description(slice, slice_type, module),
    do:
      fn -> GenServer.call(@name, {:do_description, slice, slice_type, module}, :infinity) end
      |> Telemetry.span_function_call(@prefix ++ [:do_description], %{module: module})

  @impl true
  def init([]), do: {:ok, AsyncGenServer.init_state()}

  @impl true
  def handle_call({:do_description, slice, slice_type, module}, pid, state) do
    fn -> {pid, do_description_(slice, slice_type, module)} end
    |> AsyncGenServer.start_async_task(state)
  end

  defp do_description_(slice, slice_type, module),
    do:
      ItemDescriptionOperation.new(slice, slice_type, module)
      |> ItemDescriptionOperation.set_retry_strategy(fn :database_busy, _ -> :retry_exp end)
      |> ItemDescriptionOperation.run()

  @impl true
  def handle_task_end(_, {pid, result}, _, state) do
    GenServer.reply(pid, result)
    {:remove, state}
  end
end
