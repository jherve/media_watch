defmodule MediaWatch.Parsing do
  import Ecto.Query
  alias MediaWatch.Repo
  alias MediaWatch.Catalog.Source
  alias MediaWatch.Snapshots.Snapshot
  alias MediaWatch.Parsing.{ParsedSnapshot, Slice}
  @parsed_preloads [:xml, :source]

  def do_parsing(snap = %Snapshot{}),
    do: with({:ok, cs} <- Snapshot.parse(snap), do: cs |> Repo.insert())

  def do_slicing(snap = %ParsedSnapshot{}),
    do:
      with(
        cs_list when is_list(cs_list) <- ParsedSnapshot.slice(snap),
        do: cs_list |> insert_all_slices
      )

  def get(id), do: ParsedSnapshot |> Repo.get(id) |> Repo.preload(snapshot: @parsed_preloads)
  def get_all(), do: ParsedSnapshot |> Repo.all() |> Repo.preload(snapshot: @parsed_preloads)

  def get_all_slices(item_id) do
    from(sl in Slice,
      join: ps in ParsedSnapshot,
      on: ps.id == sl.parsed_snapshot_id,
      join: snap in Snapshot,
      on: snap.id == ps.id,
      join: s in Source,
      on: snap.source_id == s.id,
      where: s.item_id == ^item_id,
      preload: [:rss_entry, :rss_channel_description]
    )
    |> Repo.all()
  end

  def get_slices_by_date(date_start, date_end) do
    from(s in Slice,
      where: s.date_start >= ^date_start and s.date_end <= ^date_end,
      preload: [:rss_entry, :rss_channel_description]
    )
    |> Repo.all()
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
end
