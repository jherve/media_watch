defmodule MediaWatch.Analysis.SlicingJob do
  @behaviour MediaWatch.Job
  alias Ecto.Multi
  alias MediaWatch.Repo
  alias MediaWatch.Parsing.ParsedSnapshot
  alias __MODULE__, as: Job

  @enforce_keys [:snapshot]
  defstruct [:snapshot]

  @impl true
  def run(%Job{snapshot: snap}),
    do:
      with(
        cs_list when is_list(cs_list) <- ParsedSnapshot.slice(snap),
        multi <-
          cs_list
          |> Enum.with_index()
          |> Enum.reduce(Multi.new(), fn {cs, idx}, multi -> multi |> Multi.insert({:facet, idx}, cs) end),
        do: multi |> Repo.transaction()
      )
end
