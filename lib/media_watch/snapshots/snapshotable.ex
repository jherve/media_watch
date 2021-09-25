defmodule MediaWatch.Snapshots.Snapshotable do
  @callback make_snapshot(any()) :: {:ok, Ecto.Changeset.t()} | {:error, atom()}

  defmacro __using__(_opts) do
    quote do
      @behaviour MediaWatch.Snapshots.Snapshotable

      defdelegate make_snapshot(source), to: MediaWatch.Catalog.Source

      defoverridable make_snapshot: 1
    end
  end
end
