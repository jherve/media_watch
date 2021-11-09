defmodule MediaWatch.AsyncGenServer do
  require Logger
  alias MediaWatch.{TaskSupervisor, Repo}
  alias __MODULE__

  def init_state(state \\ %{}), do: state |> Map.put(:tasks, %{})

  def start_async_task(fun, state, ctx \\ []) when is_function(fun, 0) and is_map(state) do
    {task, ctx} = fun |> Repo.rescue_if_busy() |> TaskSupervisor.start_retryable(ctx)
    {:noreply, put_in(state.tasks[task.ref], ctx)}
  end

  def handle_info({ref, :ok}, state) do
    Process.demonitor(ref, [:flush])
    {:noreply, state |> remove_task(ref)}
  end

  def handle_info({ref, {:error, :database_busy}}, state) do
    Process.demonitor(ref, [:flush])
    {:noreply, state |> retry_task(ref)}
  end

  def handle_info({:DOWN, ref, _, _, reason}, state) do
    Logger.warning("task #{inspect(ref)} crashed for #{inspect(reason)}")
    {:noreply, state |> remove_task(ref)}
  end

  def remove_task(state, ref), do: update_in(state.tasks, &(&1 |> Map.delete(ref)))

  def retry_task(state = %{tasks: tasks}, ref) do
    {retry, ctx} = tasks |> Map.get(ref) |> TaskSupervisor.retry_task()

    update_in(state.tasks, &(&1 |> Map.delete(ref)))
    |> put_in([:tasks, retry.ref], ctx)
  end

  defmacro __using__(_opts) do
    quote do
      use GenServer
      alias MediaWatch.AsyncGenServer

      @impl true
      defdelegate handle_info(msg, state), to: AsyncGenServer

      defoverridable handle_info: 2
    end
  end
end
