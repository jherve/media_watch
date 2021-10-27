defmodule MediaWatch.Analysis do
  import Ecto.Query
  alias MediaWatch.{Repo, PubSub}
  alias MediaWatch.Catalog.{Item, Show}
  alias MediaWatch.Parsing.Slice

  alias MediaWatch.Analysis.{
    ShowOccurrence,
    ShowOccurrence.Detail,
    Description,
    EntityRecognized,
    ShowOccurrence.Invitation,
    SliceUsage
  }

  def subscribe(item_id) do
    PubSub.subscribe("description:#{item_id}")
    PubSub.subscribe("occurrence_formatting:#{item_id}")
  end

  @spec get_all_analyzed_items() :: [Item.t()]
  def get_all_analyzed_items(),
    do:
      from([i, s, so] in item_query(),
        preload: [:channels, :description],
        order_by: i.id
      )
      |> Repo.all()

  @spec get_analyzed_item(integer()) :: [Item.t()]
  def get_analyzed_item(item_id),
    do:
      from([i, s, so] in item_query(),
        preload: [:channels, :description, show: [occurrences: :detail]],
        where: i.id == ^item_id,
        order_by: [desc: so.airing_time]
      )
      |> Repo.one()

  @spec get_analyzed_item_by_date(DateTime.t(), DateTime.t()) :: [Item.t()]
  def get_analyzed_item_by_date(date_start, date_end) do
    date_start = date_start |> Timex.to_datetime()
    date_end = date_end |> Timex.to_datetime()

    from([i, s, so] in item_query(),
      preload: [:channels, :description, show: [occurrences: :detail]],
      where: so.airing_time >= ^date_start and so.airing_time <= ^date_end,
      order_by: [i.id, desc: so.airing_time]
    )
    |> Repo.all()
  end

  defp item_query(),
    do:
      from(i in Item,
        join: s in Show,
        on: s.id == i.id,
        left_join: so in ShowOccurrence,
        on: so.show_id == s.id,
        preload: [show: {s, occurrences: so}]
      )

  @spec get_description(integer()) :: Description.t() | nil
  def get_description(item_id),
    do: Description |> Repo.get_by(item_id: item_id) |> Repo.preload([:slices])

  @spec get_occurrences(integer()) :: [ShowOccurrence.t()]
  def get_occurrences(show_id),
    do:
      from(s in ShowOccurrence, where: s.show_id == ^show_id, preload: [:detail, :slices])
      |> Repo.all()

  def classify(slice, analyzable), do: analyzable.classify(slice)

  def extract_date(slice), do: Slice.extract_date(slice)

  def identify_time_slot(dt, recurrent), do: recurrent.get_time_slot(dt)

  @spec create_occurrence(integer(), DateTime.t(), MediaWatch.Analysis.Recurrent.time_slot()) ::
          {:ok, ShowOccurrence.t()}
          | {:error, {:unique, ShowOccurrence.t()} | {:error, Ecto.Changeset.t()}}
  def create_occurrence(show_id, airing_time, {slot_start, slot_end}),
    do:
      ShowOccurrence.create_changeset(%{
        show_id: show_id,
        airing_time: airing_time,
        slot_start: slot_start,
        slot_end: slot_end
      })
      |> Repo.insert_and_retry()
      |> ShowOccurrence.explain_error(Repo)

  @spec create_slice_usage(integer(), integer(), atom()) ::
          {:ok, SliceUsage.t()} | {:error, Ecto.Changeset.t()}
  def create_slice_usage(slice_id, desc_id, type = :item_description),
    do:
      SliceUsage.create_changeset(%{slice_id: slice_id, description_id: desc_id, type: type})
      |> Repo.insert_and_retry()

  def create_slice_usage(slice_id, occ_id, slice_type),
    do:
      SliceUsage.create_changeset(%{
        slice_id: slice_id,
        show_occurrence_id: occ_id,
        type: slice_type
      })
      |> Repo.insert_and_retry()

  @spec create_occurrence_details(integer(), Slice.t()) ::
          {:ok, Detail.t()} | {:error, {:unique, Detail.t()} | {:error, Ecto.Changeset.t()}}
  def create_occurrence_details(occ_id, %Slice{type: :rss_entry, rss_entry: entry}),
    do:
      Detail.changeset(%{
        id: occ_id,
        title: entry.title,
        description: entry.description,
        link: entry.link
      })
      |> Repo.insert_and_retry()
      |> Detail.explain_create_error(Repo)

  @spec update_occurrence_details(Detail.t(), Slice.t()) ::
          {:ok, Detail.t()} | {:error, Ecto.Changeset.t()}
  def update_occurrence_details(detail = %Detail{}, _slice),
    do: Detail.changeset(detail, %{}) |> Repo.update_and_retry()

  @spec create_description(integer(), Slice.t(), atom()) ::
          {:ok, Description.t()} | {:error, Ecto.Changeset.t()}
  def create_description(item_id, slice, describable),
    do:
      describable.get_description_attrs(item_id, slice)
      |> Description.changeset()
      |> Repo.insert_and_retry()

  def insert_guests_from(occ, recognisable),
    do:
      insert_guests_from(
        occ,
        recognisable,
        function_exported?(recognisable, :get_guests_attrs, 1)
      )

  def insert_guests_from(_occ, _recognisable, false), do: []

  def insert_guests_from(occ, recognisable, true) do
    occ = occ |> Repo.preload([:detail, slices: Slice.preloads()])

    with list_of_attrs <- recognisable.get_guests_attrs(occ),
         cs_list <- Invitation.get_guests_cs(occ, list_of_attrs),
         do: cs_list |> Enum.map(&insert_guest/1)
  end

  defp insert_guest(cs) when is_struct(cs, Ecto.Changeset) do
    case cs |> Repo.insert_and_retry() |> Invitation.handle_error(Repo) do
      ok = {:ok, _} -> ok
      {:error, {:person_exists, new_cs}} -> new_cs |> insert_guest()
      e = {:error, _} -> e
    end
  end

  def insert_entities_from(slice, recognisable) do
    with cs_list when is_list(cs_list) <-
           slice
           |> recognisable.get_entities_cs()
           |> EntityRecognized.maybe_filter(recognisable),
         {:ok, res} <-
           Repo.transaction(fn repo -> cs_list |> Enum.map(&repo.insert_and_retry(&1)) end),
         do: res
  end
end
