defmodule MediaWatch.Snapshots.Snapshotable do
  @callback make_snapshot(MediaWatch.Catalog.Source.t()) ::
              {:ok, Ecto.Changeset.t()} | {:error, any()}

  defmacro __using__(_opts) do
    quote do
      @behaviour MediaWatch.Snapshots.Snapshotable

      defdelegate make_snapshot(source), to: MediaWatch.Catalog.Source

      defoverridable make_snapshot: 1
    end
  end
end
