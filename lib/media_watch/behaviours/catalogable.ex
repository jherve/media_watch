defmodule MediaWatch.Catalog.Catalogable do
  @callback insert() :: {:ok, MediaWatch.Catalog.Item.t()} | {:error, any()}
  @callback get() :: MediaWatch.Catalog.Item.t() | nil
  @callback query() :: Ecto.Query.t()
end
