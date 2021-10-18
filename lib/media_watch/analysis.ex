defmodule MediaWatch.Analysis do
  import Ecto.Query
  alias MediaWatch.{Repo, PubSub}
  alias MediaWatch.Catalog.{Item, Show}
  alias MediaWatch.Parsing.Slice
  alias MediaWatch.Analysis.{ShowOccurrence, Description, EntityRecognized, Invitation}

  def subscribe(item_id) do
    PubSub.subscribe("description:#{item_id}")
    PubSub.subscribe("occurrence_formatting:#{item_id}")
  end

  def get_all_analyzed_items(),
    do:
      from(i in Item,
        join: s in Show,
        on: s.id == i.id,
        left_join: so in ShowOccurrence,
        on: so.show_id == s.id,
        preload: [:channels, :description, show: {s, occurrences: so}],
        order_by: [desc: so.airing_time]
      )
      |> Repo.all()

  def get_analyzed_item(item_id),
    do:
      from(i in Item,
        join: s in Show,
        on: s.id == i.id,
        left_join: so in ShowOccurrence,
        on: so.show_id == s.id,
        preload: [:channels, :description, show: {s, occurrences: so}],
        where: i.id == ^item_id,
        order_by: [desc: so.airing_time]
      )
      |> Repo.one()

  def get_analyzed_item_by_date(date_start, date_end) do
    date_start = date_start |> Timex.to_datetime()
    date_end = date_end |> Timex.to_datetime()

    from(i in Item,
      join: s in Show,
      on: s.id == i.id,
      left_join: so in ShowOccurrence,
      on: so.show_id == s.id,
      preload: [:channels, :description, show: {s, occurrences: so}],
      where: so.airing_time >= ^date_start and so.airing_time <= ^date_end,
      order_by: [i.id, desc: so.airing_time]
    )
    |> Repo.all()
  end

  def get_description(item_id),
    do: Description |> Repo.get_by(item_id: item_id) |> Repo.preload([:slices])

  def get_occurrences(show_id),
    do: from(s in ShowOccurrence, where: s.show_id == ^show_id, preload: [:slices]) |> Repo.all()

  def create_description_and_store(slice, repo, describable),
    do:
      slice
      |> repo.preload(:rss_channel_description)
      |> describable.create_description()
      |> MediaWatch.Repo.insert_and_retry(repo)

  def create_occurrence_and_store(slice, repo, recurrent),
    do:
      slice
      |> repo.preload(Slice.preloads())
      |> recurrent.get_occurrence_cs()
      |> MediaWatch.Repo.insert_and_retry(repo)
      |> ShowOccurrence.explain_error(recurrent)

  def update_occurrence_and_store(occ, slice, repo, recurrent) do
    occ = occ |> repo.preload([:show, :slices])

    all_slices =
      (ShowOccurrence.query_slices_from_occurrence(occ)
       |> repo.all()
       |> repo.preload(Slice.preloads())) ++
        [slice]

    grouped = ShowOccurrence.group_slices(occ, all_slices)

    occ
    |> recurrent.get_occurrence_change_cs(
      grouped |> Map.get(:used, []),
      grouped |> Map.get(:discarded, []),
      grouped |> Map.get(:new, [])
    )
    |> MediaWatch.Repo.update_and_retry(repo)
  end

  def insert_guests_from(occ, repo, recognisable) do
    if function_exported?(recognisable, :get_guests_attrs, 1) do
      apply(recognisable, :get_guests_attrs, [occ])
      |> then(&Invitation.get_guests_cs(occ, &1))
      |> then(&Invitation.insert_guests(&1, repo))
    else
      []
    end
  end

  def insert_entities_from(slice, repo, recognisable),
    do:
      slice
      |> recognisable.get_entities_cs()
      |> EntityRecognized.maybe_filter(recognisable)
      |> EntityRecognized.insert_entities(repo)
end
