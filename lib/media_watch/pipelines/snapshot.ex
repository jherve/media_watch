defmodule MediaWatch.Snapshots.SnapshotPipeline do
  require Logger
  alias Ecto.Multi
  alias MediaWatch.{Repo, Snapshots, Parsing, Analysis}
  alias MediaWatch.Catalog.Source
  alias __MODULE__
  defstruct [:source, :module]

  def new(source = %Source{}, module), do: %SnapshotPipeline{source: source, module: module}

  def run(progress \\ %{}, pipeline, stage \\ :snapshot)

  def run(progress, pipeline = %SnapshotPipeline{source: source, module: module}, :snapshot) do
    with {:ok, snap} <- Snapshots.snapshot(module, source) do
      progress |> Map.put(:snapshot, snap) |> run(pipeline, :parsing)
    else
      {:error, :timeout} ->
        progress |> run(pipeline, :snapshot)

      {:error, e} ->
        {:error, :snapshot, e}
    end
  end

  def run(progress = %{snapshot: snap}, pipeline = %SnapshotPipeline{module: module}, :parsing) do
    case Parsing.parse(snap, module) do
      {:ok, parsed} ->
        progress |> Map.put(:parsed_snapshot, parsed) |> run(pipeline, :slicing)

      {:error, e} ->
        {:error, :parsing, e}
    end
  end

  def run(
        progress = %{parsed_snapshot: parsed},
        pipeline = %SnapshotPipeline{module: module},
        :slicing
      ) do
    case Parsing.slice(parsed, module) do
      {:ok, [], _} ->
        progress |> revert()
        {:error, :slicing, :no_new_slice}

      {:error, [], _, _errors} ->
        progress |> revert()
        {:error, :slicing, :no_new_slice}

      {:ok, ok, _} ->
        progress |> Map.put(:slices, ok) |> run(pipeline, :entity_recognition)

      {:error, ok, _, errors} ->
        Logger.warning("#{errors |> Enum.count()} errors on slices insertion in #{module}")
        progress |> Map.put(:slices, ok) |> run(pipeline, :entity_recognition)
    end
  end

  def run(
        progress = %{slices: slices},
        pipeline = %SnapshotPipeline{module: module},
        :entity_recognition
      ) do
    progress
    |> Map.put(:entities, slices |> Enum.flat_map(&Analysis.recognize_entities(&1, module)))
    |> run(pipeline, :sink)
  end

  def run(progress, %SnapshotPipeline{}, :sink) do
    {:ok,
     %{
       snapshot: progress.snapshot,
       parsed_snapshot: progress.parsed_snapshot,
       slices: progress.slices,
       entities: progress.entities
     }}
  end

  defp revert(result) do
    case do_revert(result) do
      {:ok, _} -> :ok
      {:error, :database_busy} -> do_revert(result)
      e = {:error, _, _, _} -> e
    end
  end

  defp do_revert(%{snapshot: snapshot, parsed_snapshot: parsed_snapshot}),
    do:
      Multi.new()
      |> Multi.delete(:parsed, parsed_snapshot)
      |> Multi.delete(:snapshot, snapshot)
      |> Repo.safe_transaction()
end
