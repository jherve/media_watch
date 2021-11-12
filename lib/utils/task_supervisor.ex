defmodule MediaWatch.TaskSupervisor do
  require Logger

  def start(fun) when is_function(fun, 0) do
    Task.Supervisor.async_nolink(MediaWatch.TaskSupervisor, fun)
  end

  @spec start_retryable(fun :: (() -> any()), Keyword.t()) :: {Task.t(), map()}
  def start_retryable(fun, ctx \\ []) when is_function(fun, 0) do
    {fun |> start(), ctx |> Map.new() |> Map.merge(%{nb_retries: 0, fun: fun})}
  end

  @spec retry_task(map()) :: {Task.t(), map()}
  def retry_task(ctx = %{fun: fun, nb_retries: nb_retries}) do
    {fun |> start(), %{ctx | nb_retries: nb_retries + 1}}
  end
end
