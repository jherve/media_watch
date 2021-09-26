defmodule MediaWatch.Parsing.Parsable do
  @callback parse(MediaWatch.Snapshots.Snapshot.t()) ::
              {:ok, Ecto.Changeset.t()} | {:error, any()}

  defmacro __using__(_opts) do
    quote do
      @behaviour MediaWatch.Parsing.Parsable
    end
  end
end
