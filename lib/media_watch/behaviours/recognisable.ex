defmodule MediaWatch.Analysis.Recognisable do
  alias MediaWatch.Repo
  alias MediaWatch.Parsing.Slice
  alias MediaWatch.Analysis.ShowOccurrence.Invitation

  @doc "Get a list of entities changesets from a slice"
  @callback get_entities_cs(MediaWatch.Parsing.Slice.t()) :: [Ecto.Changeset.t()]

  @doc "Return a list of the persons to blacklist from the entities recognition"
  @callback in_entities_blacklist?(binary()) :: boolean()

  @doc "Get a list of maps of persons' attributes from a show occurrence"
  @callback get_guests_attrs(MediaWatch.Analysis.ShowOccurrence.t(), hosted_module :: atom()) :: [
              map()
            ]

  @optional_callbacks in_entities_blacklist?: 1

  def insert_guests_from(occ, recognisable, hosted) do
    occ = occ |> Repo.preload([:detail, slices: Slice.preloads()])

    with list_of_attrs <- recognisable.get_guests_attrs(occ, hosted),
         cs_list <- Invitation.get_guests_cs(occ, list_of_attrs),
         do: cs_list |> Enum.map(&insert_guest/1)
  end

  defp insert_guest(cs) when is_struct(cs, Ecto.Changeset) do
    case cs |> Repo.insert() |> Invitation.handle_error(Repo) do
      ok = {:ok, _} -> ok
      {:error, {:person_exists, new_cs}} -> new_cs |> insert_guest()
      e = {:error, _} -> e
    end
  end

  def insert_entities_from(slice, recognisable) do
    with cs_list when is_list(cs_list) <- slice |> recognisable.get_entities_cs(),
         filtered when is_list(filtered) <-
           cs_list |> maybe_filter(recognisable),
         {:ok, res} <-
           Repo.transaction(fn repo -> filtered |> Enum.map(&repo.insert(&1)) end),
         do: res
  end

  defp maybe_filter(cs_list, recognisable) when is_list(cs_list),
    do: cs_list |> Enum.reject(&maybe_blacklist(&1, recognisable))

  defp maybe_blacklist(cs, recognisable) do
    if function_exported?(recognisable, :in_entities_blacklist?, 1) do
      case cs |> Ecto.Changeset.fetch_field(:label) do
        {_, label} -> apply(recognisable, :in_entities_blacklist?, [label])
        :error -> false
      end
    else
      false
    end
  end
end
