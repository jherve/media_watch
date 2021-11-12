defmodule MediaWatch.Analysis do
  import Ecto.Query
  alias MediaWatch.{Repo, PubSub}
  alias MediaWatch.Catalog.{Item, Show, Person, Channel, ChannelItem}
  alias MediaWatch.Parsing.Slice

  alias MediaWatch.Analysis.{
    ShowOccurrence,
    Description,
    ShowOccurrence.Invitation,
    Recognisable,
    Describable,
    Recurrent,
    Analyzable
  }

  def subscribe(item_id) do
    PubSub.subscribe("item:#{item_id}")
  end

  @spec get_all_analyzed_items() :: [Item.t()]
  def get_all_analyzed_items(),
    do:
      from([i, s, so] in item_query(),
        join: ci in ChannelItem,
        on: ci.item_id == i.id,
        join: c in Channel,
        on: ci.channel_id == c.id,
        preload: [:description, channels: c],
        order_by: [c.id, i.id]
      )
      |> Repo.all()

  @spec get_analyzed_item(integer()) :: [Item.t()]
  def get_analyzed_item(item_id),
    do:
      from([i, s, so] in item_query(),
        preload: [:channels, :description],
        where: i.id == ^item_id,
        order_by: [desc: so.airing_time]
      )
      |> Repo.one()

  def list_show_occurrences(person_id: person_id) do
    from([so, s, item] in show_occurrence_query(),
      join: i in Invitation,
      on: i.show_occurrence_id == so.id,
      join: p in Person,
      on: p.id == i.person_id,
      preload: [:detail, guests: p, show: [item: :description]],
      where: p.id == ^person_id,
      order_by: [desc: so.airing_time]
    )
    |> Repo.all()
  end

  @spec list_show_occurrences(integer()) :: [ShowOccurrence.t()]
  def list_show_occurrences(item_id),
    do:
      from([so, _, i] in show_occurrence_query(),
        preload: [:detail, :guests, show: [item: :description]],
        where: i.id == ^item_id,
        order_by: [desc: so.airing_time]
      )
      |> Repo.all()

  @spec list_show_occurrences(DateTime.t(), DateTime.t()) :: [ShowOccurrence.t()]
  def list_show_occurrences(dt_start = %DateTime{}, dt_end = %DateTime{}) do
    from([so, s, i] in show_occurrence_query(),
      preload: [:detail, :guests, show: [item: :description]],
      where: so.airing_time >= ^dt_start and so.airing_time <= ^dt_end,
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

  defp show_occurrence_query(),
    do:
      from(so in ShowOccurrence,
        join: s in Show,
        on: so.show_id == s.id,
        join: i in Item,
        on: s.id == i.id,
        preload: [show: {s, item: i}]
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

  defdelegate create_occurrence(show_id, airing_time, slot), to: Recurrent

  defdelegate create_slice_usage(slice_id, occ_id, slice_type), to: Analyzable

  defdelegate create_occurrence_details(occ_id, slice), to: Recurrent
  defdelegate update_occurrence_details(detail, slice), to: Recurrent

  defdelegate create_description(item_id, slice, describable), to: Describable

  defdelegate insert_guests_from(occ, recognisable, hosted), to: Recognisable
  defdelegate insert_entities_from(slice, recognisable), to: Recognisable
end
