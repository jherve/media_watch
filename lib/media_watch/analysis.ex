defmodule MediaWatch.Analysis do
  import Ecto.Query
  import Ecto.Changeset
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
        preload: [:channels, :description, show: {s, occurrences: {so, :detail}}],
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
      preload: [:channels, :description, show: {s, occurrences: {so, :detail}}],
      where: so.airing_time >= ^date_start and so.airing_time <= ^date_end,
      order_by: [i.id, desc: so.airing_time]
    )
    |> Repo.all()
  end

  def get_description(item_id),
    do: Description |> Repo.get_by(item_id: item_id) |> Repo.preload([:slices])

  def get_occurrences(show_id),
    do:
      from(s in ShowOccurrence, where: s.show_id == ^show_id, preload: [:detail, :slices])
      |> Repo.all()

  def classify(slice, analyzable), do: analyzable.classify(slice)

  def extract_date(slice), do: Slice.extract_date(slice)

  def identify_time_slot(dt, recurrent), do: recurrent.get_time_slot(dt)

  def create_occurrence(show_id, airing_time, {slot_start, slot_end}),
    do:
      ShowOccurrence.changeset(%{
        show_id: show_id,
        airing_time: airing_time,
        slot_start: slot_start,
        slot_end: slot_end
      })

  def explain_create_occurrence_error(
        {:error,
         cs = %{
           errors: [
             show_id:
               {_,
                [
                  constraint: :unique,
                  constraint_name: "show_occurrences_show_id_airing_time_index"
                ]}
           ]
         }}
      ) do
    with {_, airing_time} <- cs |> fetch_field(:airing_time),
         occ when not is_nil(occ) <- ShowOccurrence |> Repo.get_by(airing_time: airing_time),
         do: {:error, {:unique, occ}}
  end

  def explain_create_occurrence_error(ok_or_other_error), do: ok_or_other_error

  def create_slice_usage(slice_id, desc_id, type = :item_description),
    do: SliceUsage.changeset(%{slice_id: slice_id, description_id: desc_id, type: type})

  def create_slice_usage(slice_id, occ_id, slice_type),
    do: SliceUsage.changeset(%{slice_id: slice_id, show_occurrence_id: occ_id, type: slice_type})

  def create_occurrence_details(occ_id, %Slice{type: :rss_entry, rss_entry: entry}),
    do:
      Detail.changeset(%{
        id: occ_id,
        title: entry.title,
        description: entry.description,
        link: entry.link
      })

  def explain_create_occurrence_detail_error(
        {:error,
         cs = %{
           errors: [
             id:
               {_,
                [
                  constraint: :unique,
                  constraint_name: "show_occurrences_details_id_index"
                ]}
           ]
         }}
      ) do
    with {_, id} <- cs |> fetch_field(:id),
         detail when not is_nil(detail) <- Detail |> Repo.get(id),
         do: {:error, {:unique, detail}}
  end

  def explain_create_occurrence_detail_error(ok_or_other_error), do: ok_or_other_error

  def update_occurrence_details(detail = %Detail{}, _slice),
    do: Detail.changeset(detail, %{})

  def create_description(item_id, slice, describable),
    do: describable.get_description_attrs(item_id, slice) |> Description.changeset()

  def insert_guests_from(occ, recognisable) do
    if function_exported?(recognisable, :get_guests_attrs, 1) do
      occ = occ |> Repo.preload(:detail)

      apply(recognisable, :get_guests_attrs, [occ])
      |> then(&Invitation.get_guests_cs(occ, &1))
      |> then(&Invitation.insert_guests(&1))
    else
      []
    end
  end

  def insert_entities_from(slice, recognisable),
    do:
      slice
      |> recognisable.get_entities_cs()
      |> EntityRecognized.maybe_filter(recognisable)
      |> EntityRecognized.insert_entities()
end
