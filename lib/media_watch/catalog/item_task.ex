defmodule MediaWatch.Catalog.ItemTask do
  use GenServer
  require Logger
  alias MediaWatch.{Repo, PubSub, Parsing}
  alias MediaWatch.Catalog.Item
  alias MediaWatch.Snapshots.Snapshot
  alias MediaWatch.Parsing.{ParsedSnapshot, Slice}
  alias MediaWatch.Analysis.{Description, ShowOccurrence}
  @max_snapshot_retries 3

  def start_link(module) when is_atom(module) do
    GenServer.start_link(__MODULE__, module, name: module)
  end

  def do_snapshots(module) when is_atom(module), do: GenServer.cast(module, :do_snapshots)

  @impl true
  def init(module) when is_atom(module) do
    case module.get(Repo) do
      nil ->
        case module.insert(Repo) do
          {:ok, item} ->
            item |> init()

          {:error, _} ->
            Logger.warning("Could not start #{module}")
            {:ok, nil}
        end

      item ->
        item |> init()
    end
  end

  def init(item = %Item{id: id}) do
    PubSub.subscribe("snapshots:#{id}")
    PubSub.subscribe("parsing:#{id}")
    PubSub.subscribe("slicing:#{id}")
    {:ok, %{id: id, item: item, sources: item.sources}}
  end

  @impl true
  def handle_cast(:do_snapshots, state = %{sources: sources}) do
    success_snaps =
      sources
      |> Enum.map(&make_snapshot(&1, state.item.module))
      |> keep_ok_results()

    success_snaps |> publish_result(state.id)

    {:noreply, state}
  end

  @impl true
  def handle_info(snap = %Snapshot{}, state) do
    snap |> parse_snapshot(state.item.module) |> publish_result(state.id)

    {:noreply, state}
  end

  def handle_info(snap = %ParsedSnapshot{}, state) do
    snap |> slice_snapshot(state.item.module) |> publish_result(state.id)

    {:noreply, state}
  end

  def handle_info(slice = %Slice{type: :rss_channel_description}, state) do
    slice |> state.item.module.describe() |> Repo.insert() |> publish_result(state.id)

    {:noreply, state}
  end

  def handle_info(slice = %Slice{type: :rss_entry}, state) do
    slice |> state.item.module.format_occurrence() |> Repo.insert() |> publish_result(state.id)

    {:noreply, state}
  end

  defp make_snapshot(source, module, nb_retries \\ 0)

  defp make_snapshot(_, module, nb_retries) when nb_retries > @max_snapshot_retries do
    Logger.warning("Could not snapshot #{module} despite #{nb_retries} retries")
    {:error, reason: :max_retries}
  end

  defp make_snapshot(source, module, nb_retries) do
    case module.make_snapshot_and_insert(source, MediaWatch.Repo) do
      ok = {:ok, _} ->
        ok

      {:error, %{reason: :timeout}} ->
        Logger.warning("Retrying snapshot for #{module}")
        make_snapshot(source, module, nb_retries + 1)

      error = {:error, _} ->
        error
    end
  end

  defp parse_snapshot(snap = %Snapshot{}, module) do
    with {:ok, cs} <- module.parse(snap), do: cs |> Repo.insert()
  end

  defp slice_snapshot(snap = %ParsedSnapshot{}, module) do
    snap = Parsing.get(snap.id)

    with cs_list when is_list(cs_list) <- module.slice(snap) do
      case cs_list |> insert_all_slices do
        {:ok, ok, _} ->
          ok

        {:error, ok, _, errors} ->
          Logger.error("#{errors |> Enum.count()} errors on slices insertion")
          ok
      end
    end
  end

  defp insert_all_slices(cs_list) do
    res =
      cs_list
      |> Enum.map(&Repo.insert/1)
      |> Enum.group_by(&Slice.get_error_reason/1, fn {_, val} -> val end)

    {ok, unique, failures} =
      {res |> Map.get(:ok, []), res |> Map.get(:unique, []), res |> Map.get(:error, [])}

    if failures |> Enum.empty?(), do: {:ok, ok, unique}, else: {:error, ok, unique, failures}
  end

  defp keep_ok_results(res_list) when is_list(res_list),
    do:
      res_list
      |> Enum.filter(&match?({:ok, _}, &1))
      |> Enum.map(fn {:ok, res} -> res end)

  defp publish_result(res_list, item_id) when is_list(res_list),
    do: res_list |> Enum.each(&publish_result(&1, item_id))

  defp publish_result({:ok, obj}, item_id), do: publish_result(obj, item_id)

  defp publish_result(snap = %Snapshot{}, item_id),
    do: PubSub.broadcast("snapshots:#{item_id}", snap)

  defp publish_result(parsed = %ParsedSnapshot{}, item_id),
    do: PubSub.broadcast("parsing:#{item_id}", parsed)

  defp publish_result(slice = %Slice{}, item_id),
    do: PubSub.broadcast("slicing:#{item_id}", slice)

  defp publish_result(desc = %Description{}, item_id),
    do: PubSub.broadcast("description:#{item_id}", {:new_description, desc})

  defp publish_result(occ = %ShowOccurrence{}, item_id),
    do: PubSub.broadcast("occurrence_formatting:#{item_id}", {:new_occurrence, occ})
end
