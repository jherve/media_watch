defmodule MediaWatch.Analysis do
  import Ecto.Query
  alias MediaWatch.{Repo, Catalog, PubSub}
  alias MediaWatch.Parsing.ParsedSnapshot
  alias MediaWatch.Snapshots.Snapshot
  alias MediaWatch.Catalog.Source
  alias MediaWatch.Analysis.Facet

  def do_slicing(snap = %ParsedSnapshot{}),
    do:
      with(
        cs_list when is_list(cs_list) <- ParsedSnapshot.slice(snap),
        do: cs_list |> insert_all_facets
      )

  def get_all_facets(item_id) do
    from(f in Facet,
      join: ps in ParsedSnapshot,
      on: ps.id == f.parsed_snapshot_id,
      join: snap in Snapshot,
      on: snap.id == ps.id,
      join: s in Source,
      on: snap.source_id == s.id,
      where: s.item_id == ^item_id,
      preload: [:show_occurrence, :description],
      order_by: [desc: f.date_start]
    )
    |> Repo.all()
  end

  def subscribe(item_id),
    do:
      Catalog.get_source_ids(item_id)
      |> Enum.map(&PubSub.subscribe("slicing:#{&1}"))

  defp insert_all_facets(cs_list) do
    res =
      cs_list
      |> Enum.map(&Repo.insert/1)
      |> Enum.group_by(&get_error_reason/1, fn {_, val} -> val end)

    {ok, unique, failures} =
      {res |> Map.get(:ok, []), res |> Map.get(:unique, []), res |> Map.get(:error, [])}

    if failures |> Enum.empty?(), do: {:ok, ok, unique}, else: {:error, ok, unique, failures}
  end

  defp get_error_reason({:ok, _obj}), do: :ok

  defp get_error_reason(
         {:error,
          %{
            errors: [
              source_id:
                {_,
                 [
                   constraint: :unique,
                   constraint_name: "facets_source_id_date_start_date_end_index"
                 ]}
            ]
          }}
       ),
       do: :unique

  defp get_error_reason({:error, _cs}), do: :error
end
