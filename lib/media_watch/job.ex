defmodule MediaWatch.Job do
  @callback run(any()) :: {:ok, result :: any()} | {:error, atom()}
end
