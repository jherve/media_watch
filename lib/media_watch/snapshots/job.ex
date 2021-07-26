defmodule MediaWatch.Snapshots.Job do
  @behaviour MediaWatch.Job
  alias MediaWatch.Repo
  alias MediaWatch.Catalog.Source
  alias __MODULE__, as: Job

  @enforce_keys [:source]
  defstruct [:source]

  @impl true
  def run(%Job{source: source}),
    do: with({:ok, cs} <- Source.make_snapshot(source), do: cs |> Repo.insert())
end
