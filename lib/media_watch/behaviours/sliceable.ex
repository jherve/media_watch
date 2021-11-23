defmodule MediaWatch.Parsing.Sliceable do
  @type slice_kind :: :replay | :excerpt | :main_page
  alias Ecto.Changeset
  alias MediaWatch.Parsing.{ParsedSnapshot, Slice}

  @callback into_list_of_slice_attrs(ParsedSnapshot.t()) :: [map()]
  @callback into_slice_cs(map(), ParsedSnapshot.t()) :: Ecto.Changeset.t()
  @callback get_slice_kind(Slice.t()) :: slice_kind()

  @spec get_slice_kind!(Changeset.t(), atom()) :: slice_kind()
  def get_slice_kind!(slice_cs = %Changeset{data: %Slice{}}, module) do
    with true <- function_exported?(module, :get_slice_kind, 1),
         {:ok, slice} <- slice_cs |> Changeset.apply_action(:change) do
      module.get_slice_kind(slice)
    else
      _ -> nil
    end
  end

  def slice(parsed = %ParsedSnapshot{}, module),
    do:
      parsed
      |> module.into_list_of_slice_attrs()
      |> Enum.map(&module.into_slice_cs(&1, parsed))
      |> Enum.map(&(&1 |> Changeset.change(%{kind: &1 |> get_slice_kind!(module)})))

  @optional_callbacks get_slice_kind: 1
end
