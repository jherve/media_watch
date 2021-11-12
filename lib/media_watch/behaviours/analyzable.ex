defmodule MediaWatch.Analysis.Analyzable do
  alias MediaWatch.Repo
  alias MediaWatch.Parsing.Slice
  alias MediaWatch.Analysis.SliceUsage

  @type slice_type() ::
          :item_description | :show_occurrence_description | :show_occurrence_excerpt

  @callback classify(Slice.t()) :: slice_type()

  @spec create_slice_usage(integer(), integer(), atom()) ::
          {:ok, SliceUsage.t()} | {:error, Ecto.Changeset.t()}
  def create_slice_usage(slice_id, desc_id, type = :item_description),
    do:
      SliceUsage.create_changeset(%{slice_id: slice_id, description_id: desc_id, type: type})
      |> Repo.insert()

  def create_slice_usage(slice_id, occ_id, slice_type),
    do:
      SliceUsage.create_changeset(%{
        slice_id: slice_id,
        show_occurrence_id: occ_id,
        type: slice_type
      })
      |> Repo.insert()
end
