defmodule MediaWatch.Analysis.Recognisable do
  @doc "Get a list of maps of persons' attributes from a show occurrence"
  @callback get_guests_attrs(MediaWatch.Analysis.ShowOccurrence.t()) :: [map()]

  @doc "Get a list of invitation changesets from a list of maps of persons' attributes"
  @callback get_guests_cs(MediaWatch.Analysis.ShowOccurrence.t(), [map()]) :: [Ecto.Changeset.t()]

  @doc "Insert a list of Invitation changesets into a repo"
  @callback insert_guests([Ecto.Changeset.t()], Ecto.Repo.t()) :: [any()]

  @doc "Run `get_guests_attrs` / `get_guests_cs` / `insert_guests` functions on a given show occurrence"
  @callback insert_guests_from(MediaWatch.Analysis.ShowOccurrence.t(), Ecto.Repo.t()) :: [any()]

  @optional_callbacks get_guests_attrs: 1, get_guests_cs: 2, insert_guests: 2

  defmacro __using__(_opts) do
    quote do
      @behaviour MediaWatch.Analysis.Recognisable

      @impl true
      def insert_guests_from(occ, repo) do
        if function_exported?(__MODULE__, :get_guests_attrs, 1) and
             function_exported?(__MODULE__, :get_guests_cs, 2) and
             function_exported?(__MODULE__, :insert_guests, 2) do
          apply(__MODULE__, :get_guests_attrs, [occ])
          |> then(&apply(__MODULE__, :get_guests_cs, [occ, &1]))
          |> then(&apply(__MODULE__, :insert_guests, [&1, repo]))
        else
          []
        end
      end
    end
  end
end
