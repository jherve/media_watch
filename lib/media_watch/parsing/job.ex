defmodule MediaWatch.Parsing.Job do
  @behaviour MediaWatch.Job
  alias MediaWatch.Repo
  alias MediaWatch.Snapshots.Snapshot
  alias __MODULE__, as: Job

  @enforce_keys [:snapshot]
  defstruct [:snapshot]

  @impl true
  def run(%Job{snapshot: snap}),
    do: with({:ok, cs} <- Snapshot.parse(snap), do: cs |> Repo.insert())
end
