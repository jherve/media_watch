defmodule MediaWatch.Analysis.Describable do
  alias MediaWatch.Repo
  alias MediaWatch.Analysis.Description
  @callback get_description_attrs(integer(), MediaWatch.Parsing.Slice.t()) :: map()

  @spec create_description(integer(), Slice.t(), atom()) ::
          {:ok, Description.t()} | {:error, Ecto.Changeset.t()}
  def create_description(item_id, slice, describable),
    do:
      describable.get_description_attrs(item_id, slice)
      |> Description.changeset()
      |> Repo.insert()
end
