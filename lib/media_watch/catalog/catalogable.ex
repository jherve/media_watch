defmodule MediaWatch.Catalog.Catalogable do
  @callback get_repo() :: Ecto.Repo.t()
  @callback insert() :: {:ok, MediaWatch.Catalog.Item.t()} | {:error, any()}
  @callback get() :: MediaWatch.Catalog.Item.t() | nil

  defmacro __using__(opts) do
    quote bind_quoted: [opts: opts] do
      @behaviour MediaWatch.Catalog.Catalogable
      @repo opts[:repo] || raise("`repo` should be set")

      @impl true
      def get_repo(), do: @repo
    end
  end
end
