defmodule MediaWatch.Analysis do
  import Ecto.Query
  alias MediaWatch.{Repo, Catalog, PubSub}
  alias MediaWatch.Catalog.{Item, Show}
  alias MediaWatch.Parsing.Slice
  alias MediaWatch.Analysis.{Description, ShowOccurrence}

  def subscribe(item_id) do
    PubSub.subscribe("description:#{item_id}")
    PubSub.subscribe("occurrence_formatting:#{item_id}")
  end

  def get_analyzed_item(item_id),
    do:
      from(i in Item,
        join: s in Show,
        on: s.id == i.id,
        left_join: so in ShowOccurrence,
        on: so.show_id == s.id,
        preload: [:channels, :description, show: {s, occurrences: so}],
        where: i.id == ^item_id,
        order_by: [desc: so.date_start]
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
      where: so.date_start >= ^date_start and so.date_start <= ^date_end,
      order_by: [i.id, desc: so.date_start]
    )
    |> Repo.all()
  end

  def make_description(slice = %Slice{}), do: Description.from(slice) |> Repo.insert()

  def make_show_occurrence(slice = %Slice{}) do
    show_id = Catalog.get_show_id(slice.source_id)
    ShowOccurrence.from(slice, show_id) |> Repo.insert()
  end
end
