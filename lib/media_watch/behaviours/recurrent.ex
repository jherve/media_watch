defmodule MediaWatch.Analysis.Recurrent do
  alias MediaWatch.Repo
  alias MediaWatch.Parsing.Slice
  alias MediaWatch.Analysis.ShowOccurrence
  alias MediaWatch.Analysis.ShowOccurrence.Detail

  @type time_slot() :: {start :: DateTime.t(), end_ :: DateTime.t()}

  @callback get_airing_schedule() :: Crontab.CronExpression.t()
  @callback get_time_zone() :: Timex.TimezoneInfo.t()
  @callback get_duration() :: duration_seconds :: integer()

  @spec get_airing_time(DateTime.t(), atom()) :: DateTime.t() | {:error, atom()}
  def get_airing_time(dt, recurrent) do
    dt_tz = dt |> to_time_zone(recurrent)

    recurrent.get_airing_schedule()
    |> MediaWatch.Schedule.get_airing_time(dt_tz)
  end

  @spec get_time_slot(DateTime.t(), atom()) :: time_slot()
  def get_time_slot(dt, recurrent) do
    dt_tz = dt |> to_time_zone(recurrent)
    recurrent.get_airing_schedule() |> MediaWatch.Schedule.get_time_slot!(dt_tz)
  end

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
      |> Repo.insert()
      |> ShowOccurrence.explain_error(Repo)

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
      |> Repo.insert()
      |> Detail.explain_create_error(Repo)

  def create_occurrence_details(occ_id, %Slice{type: :html_preview_card, html_preview_card: item}),
    do:
      Detail.changeset(%{
        id: occ_id,
        title: item.title,
        description: item.text,
        link: item.link
      })
      |> Repo.insert()
      |> Detail.explain_create_error(Repo)

  @spec update_occurrence_details(Detail.t(), Slice.t()) ::
          {:ok, Detail.t()} | {:error, Ecto.Changeset.t()}
  def update_occurrence_details(detail = %Detail{}, _slice),
    do: Detail.changeset(detail, %{}) |> Repo.update()

  defp to_time_zone(dt, recurrent), do: dt |> Timex.Timezone.convert(recurrent.get_time_zone())
end
