defmodule MediaWatch.Parsing.Sliceable do
  @callback slice(MediaWatch.Parsing.ParsedSnapshot.t()) :: [
              {:ok, Ecto.Changeset.t()} | {:error, atom()}
            ]

  defmacro __using__(_opts) do
    quote do
      @behaviour MediaWatch.Parsing.Sliceable
    end
  end
end
