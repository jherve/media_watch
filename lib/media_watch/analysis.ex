defmodule MediaWatch.Analysis do
  import Ecto.Query
  alias MediaWatch.{Repo, PubSub}
  alias MediaWatch.Catalog.{Item, Show, Person, Channel, ChannelItem}

  alias MediaWatch.Analysis.{
    ShowOccurrence,
    ShowOccurrence.Invitation,
    EntityRecognitionServer,
    ShowOccurrencesServer,
    ItemDescriptionServer,
    DescriptionSliceAnalysisPipeline,
    OccurrenceSliceAnalysisPipeline
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
      preload: [:detail, invitations: {i, person: p}, guests: p, show: [item: :description]],
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

  def classify(slice, analyzable), do: analyzable.classify(slice)

  def run_occurrence_pipeline(slice, type, module, run_details?),
    do:
      OccurrenceSliceAnalysisPipeline.new(slice, type, module, run_details?)
      |> OccurrenceSliceAnalysisPipeline.run()

  def run_description_pipeline(slice, type, module),
    do:
      DescriptionSliceAnalysisPipeline.new(slice, type, module)
      |> DescriptionSliceAnalysisPipeline.run()

  defdelegate recognize_entities(slice, module), to: EntityRecognitionServer
  defdelegate detect_occurrence(slice, slice_type, module), to: ShowOccurrencesServer
  defdelegate add_details(occurrence, slice), to: ShowOccurrencesServer
  defdelegate do_guest_detection(occurrence, recognizable, hosted), to: ShowOccurrencesServer
  defdelegate do_description(slice, slice_type, module), to: ItemDescriptionServer
end
