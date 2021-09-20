defmodule MediaWatch.Analysis do
  import Ecto.Query
  alias MediaWatch.{Repo, Catalog, PubSub}
  alias MediaWatch.Parsing.ParsedSnapshot
  alias MediaWatch.Snapshots.Snapshot
  alias MediaWatch.Catalog.Source
  alias MediaWatch.Analysis.Slice

  def do_slicing(snap = %ParsedSnapshot{}),
    do:
      with(
        cs_list when is_list(cs_list) <- ParsedSnapshot.slice(snap),
        do: cs_list |> insert_all_slices
      )

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

  def subscribe(item_id),
    do:
      Catalog.get_source_ids(item_id)
      |> Enum.map(&PubSub.subscribe("slicing:#{&1}"))

  defp insert_all_slices(cs_list) do
    res =
      cs_list
      |> Enum.map(&Repo.insert/1)
      |> Enum.group_by(&get_error_reason/1, fn {_, val} -> val end)

    {ok, unique, failures} =
      {res |> Map.get(:ok, []), res |> Map.get(:unique, []), res |> Map.get(:error, [])}

    if failures |> Enum.empty?(), do: {:ok, ok, unique}, else: {:error, ok, unique, failures}
  end

  defp get_error_reason({:ok, _obj}), do: :ok

  # TODO : for some reason (a bug in Ecto ?) the constraint name does not appear as
  # its actual name : "slices_rss_channel_descriptions_index" but with a name that appears
  # to be made-up by Ecto
  defp get_error_reason(
         {:error,
          %{
            errors: [
              source_id:
                {_,
                 [
                   constraint: :unique,
                   constraint_name: "slices_source_id_index"
                 ]}
            ]
          }}
       ),
       do: :unique

  defp get_error_reason(
         {:error,
          %{
            errors: [],
            changes: %{
              rss_entry: %{
                errors: [
                  guid: {_, [constraint: :unique, constraint_name: "rss_entries_guid_index"]}
                ]
              }
            }
          }}
       ),
       do: :unique

  defp get_error_reason({:error, _cs}), do: :error
end
