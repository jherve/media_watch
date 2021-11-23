defmodule MediaWatch.AsyncGenServer do
  require Logger
  alias MediaWatch.TaskSupervisor
  alias __MODULE__

  @callback handle_task_end(
              task_ref :: reference(),
              task_result :: any(),
              task_context :: any(),
              state :: any()
            ) ::
              {:retry, state :: any()} | {:remove, state :: any()}
  @callback handle_task_failure(task_ref :: reference(), failure_reason :: any(), state :: any()) ::
              {:retry, state :: any()} | {:remove, state :: any()}

  def init_state(state \\ %{}), do: state |> Map.put(:tasks, %{})

  @spec start_async_task(fun :: (() -> any()), map(), map()) :: {:noreply, map()}
  def start_async_task(fun, state, ctx \\ %{})
      when is_function(fun, 0) and is_map(state) and is_map(ctx) do
    {task, ctx} = fun |> TaskSupervisor.start_retryable(ctx)
    {:noreply, put_in(state.tasks[task.ref], ctx)}
  end

  def handle_info({ref, res}, state = %{tasks: tasks}, async_server) do
    Process.demonitor(ref, [:flush])
    ctx = tasks |> Map.get(ref)

    case async_server.handle_task_end(ref, res, ctx, state) do
      {:remove, state} -> {:noreply, state |> remove_task(ref)}
      {:retry, state} -> {:noreply, state |> retry_task(ref)}
    end
  end

  def handle_info({:DOWN, ref, _, _, {exception, _stacktrace}}, state, async_server) do
    case async_server.handle_task_failure(ref, exception, state) do
      {:remove, state} -> {:noreply, state |> remove_task(ref)}
      {:retry, state} -> {:noreply, state |> retry_task(ref)}
    end
  end

  defp remove_task(state, ref), do: update_in(state.tasks, &(&1 |> Map.delete(ref)))

  defp retry_task(state = %{tasks: tasks}, ref) do
    {retry, ctx} = tasks |> Map.get(ref) |> TaskSupervisor.retry_task()

    update_in(state.tasks, &(&1 |> Map.delete(ref)))
    |> put_in([:tasks, retry.ref], ctx)
  end

  defmacro __using__(_opts) do
    quote do
      use GenServer
      @behaviour AsyncGenServer
      alias MediaWatch.AsyncGenServer

      @impl true
      def handle_info(msg, state), do: AsyncGenServer.handle_info(msg, state, __MODULE__)

      @impl true
      def handle_task_failure(_, _, state) do
        {:remove, state}
      end

      defoverridable handle_info: 2, handle_task_failure: 3
    end
  end
end
