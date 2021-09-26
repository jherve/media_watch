defmodule MediaWatch.Catalog.Catalogable do
  @callback insert(Ecto.Repo.t()) :: {:ok, MediaWatch.Catalog.Item.t()} | {:error, any()}
  @callback get(Ecto.Repo.t()) :: MediaWatch.Catalog.Item.t() | nil
end
