defmodule MediaWatch.Analysis.Describable do
  @callback create_description(any()) :: any()
  @callback create_description_and_store(any(), Ecto.Repo.t()) :: any()
end
