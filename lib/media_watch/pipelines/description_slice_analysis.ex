defmodule MediaWatch.Analysis.DescriptionSliceAnalysisPipeline do
  require Logger
  alias MediaWatch.Analysis
  alias MediaWatch.Parsing.Slice
  alias __MODULE__
  defstruct [:slice, :module]

  def new(slice = %Slice{}, module),
    do: %DescriptionSliceAnalysisPipeline{slice: slice, module: module}

  def run(progress \\ %{}, pipeline, stage \\ :item_description)

  def run(_, %DescriptionSliceAnalysisPipeline{slice: slice, module: module}, _) do
    case Analysis.do_description(slice, module) do
      {:ok, desc} -> {:ok, %{description: desc}}
      {:already, _} -> {:ok, %{}}
      e = {:error, _} -> e
    end
  end
end
