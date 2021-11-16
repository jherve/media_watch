defmodule MediaWatch.OperationWithRetry do
  @type retry_strategy :: :retry | :retry_exp | :abort
  @type retry_strategy_fun ::
          (error_reason :: atom(), nb_retries :: integer() -> retry_strategy())

  @callback run(any()) :: {:ok, any()} | {:error, any()}

  defguardp is_action_with_retry(operation)
            when is_struct(operation) and is_map_key(operation, :retries) and
                   is_map_key(operation, :retry_strategy)

  def init_retries(operation = %{retries: nil}, errors_with_retry)
      when is_action_with_retry(operation) and is_list(errors_with_retry),
      do: %{operation | retries: errors_with_retry |> Map.new(&{&1, 0})}

  @spec set_retry_strategy(any(), retry_strategy_fun) :: any()
  def set_retry_strategy(operation, retry_fun)
      when is_action_with_retry(operation) and is_function(retry_fun, 2),
      do: %{operation | retry_strategy: retry_fun}

  def maybe_retry(operation = %{retry_strategy: retry_fun}, error)
      when is_action_with_retry(operation),
      do: maybe_retry(operation, error, retry_fun.(error, operation.retries[error]))

  def maybe_retry(operation, error, :retry_exp) when is_action_with_retry(operation) do
    # Use an exponential backoff strategy : the process will sleep for n milliseconds,
    # n being randomly chosen between 0 and min(1000, 2^nb_retries).
    upper_bound = :math.pow(2, operation.retries[error] + 1) |> round() |> min(1000)
    0..upper_bound |> Enum.random() |> Process.sleep()
    maybe_retry(operation, error, :retry)
  end

  def maybe_retry(operation = %action_type{}, error, :retry)
      when is_action_with_retry(operation) do
    update_in(operation.retries[error], &(&1 + 1)) |> action_type.run()
  end

  def maybe_retry(operation, error, :abort) when is_action_with_retry(operation),
    do: {:error, error}
end
