defmodule MediaWatch.Parsing.Sliceable do
  @callback slice(any()) :: [{:ok, Ecto.Changeset.t()} | {:error, atom()}]

  defmacro __using__(_opts) do
    quote do
      @behaviour MediaWatch.Parsing.Sliceable

      defdelegate slice(parsed), to: MediaWatch.Parsing.ParsedSnapshot

      defoverridable slice: 1
    end
  end
end
