defmodule MediaWatch.Parsing.Parsable do
  @callback parse(MediaWatch.Snapshots.Snapshot.t()) ::
              {:ok, Ecto.Changeset.t()} | {:error, any()}

  defmacro __using__(_opts) do
    quote do
      @behaviour MediaWatch.Parsing.Parsable

      defdelegate parse(source), to: MediaWatch.Snapshots.Snapshot

      defoverridable parse: 1
    end
  end
end
