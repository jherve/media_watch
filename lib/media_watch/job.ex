defmodule MediaWatch.Job do
  @callback run(any()) ::
              {:ok, result :: struct()} | {:ok, list_of_results :: [struct()]} | {:error, atom()}
end
