defmodule MediaWatch.Analysis.DescriptionSliceAnalysisPipeline do
  require Logger
  alias MediaWatch.Analysis
  alias MediaWatch.Parsing.Slice
  alias __MODULE__
  defstruct [:slice, :slice_type, :module]

  def new(slice = %Slice{}, slice_type, module),
    do: %DescriptionSliceAnalysisPipeline{slice: slice, slice_type: slice_type, module: module}

  def run(progress \\ %{}, pipeline, stage \\ :item_description)

  def run(_, %DescriptionSliceAnalysisPipeline{slice: slice, slice_type: type, module: module}, _) do
    case Analysis.do_description(slice, type, module) do
      {:ok, desc} -> {:ok, %{description: desc}}
      {:already, _} -> {:ok, %{}}
      e = {:error, _} -> e
    end
  end
end
