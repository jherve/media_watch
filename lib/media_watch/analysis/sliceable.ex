defmodule MediaWatch.Analysis.Sliceable do
  @callback slice(any()) :: [{:ok, Ecto.Changeset.t()} | {:error, atom()}]
end
