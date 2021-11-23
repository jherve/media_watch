defmodule MediaWatch.Analysis.OccurrenceSliceAnalysisPipeline do
  require Logger
  alias MediaWatch.Analysis
  alias MediaWatch.Parsing.Slice
  alias __MODULE__
  defstruct [:slice, :module, :run_details?]

  def new(slice = %Slice{kind: kind}, module),
    do: %OccurrenceSliceAnalysisPipeline{
      slice: slice,
      module: module,
      run_details?: kind != :excerpt
    }

  def run(progress \\ %{}, pipeline, stage \\ :occurrence_detection)

  def run(
        progress,
        pipeline = %OccurrenceSliceAnalysisPipeline{slice: slice, module: module},
        :occurrence_detection
      ) do
    case Analysis.detect_occurrence(slice, module) do
      {status, occ} when status in [:ok, :already] ->
        next = if pipeline.run_details?, do: :add_details, else: :guest_detection
        progress |> Map.put(:occurrence, occ) |> run(pipeline, next)

      {:error, e} ->
        {:error, :occurrence_detection, e}
    end
  end

  def run(
        progress = %{occurrence: occ},
        pipeline = %OccurrenceSliceAnalysisPipeline{slice: slice},
        :add_details
      ) do
    case Analysis.add_details(occ, slice) do
      {status, detail} when status in [:ok, :updated] ->
        progress |> Map.put(:detail, detail) |> run(pipeline, :guest_detection)

      e = {:error, _} ->
        {:error, :add_details, e}
    end
  end

  def run(
        progress = %{occurrence: occ},
        pipeline = %OccurrenceSliceAnalysisPipeline{module: module},
        :guest_detection
      ) do
    case Analysis.do_guest_detection(occ, module, module) do
      guests when is_list(guests) ->
        progress |> Map.put(:guests, guests) |> run(pipeline, :sink)

      e = {:error, _} ->
        {:error, :guest_detection, e}
    end
  end

  def run(progress, %OccurrenceSliceAnalysisPipeline{run_details?: true}, :sink) do
    {:ok, %{occurrence: progress.occurrence, detail: progress.detail, guests: progress.guests}}
  end

  def run(progress, %OccurrenceSliceAnalysisPipeline{run_details?: false}, :sink) do
    {:ok, %{occurrence: progress.occurrence, guests: progress.guests}}
  end
end
