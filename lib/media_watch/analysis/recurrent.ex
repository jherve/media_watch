defmodule MediaWatch.Analysis.Recurrent do
  @type time_slot() :: {start :: DateTime.t(), end_ :: DateTime.t()}

  @callback get_airing_schedule() :: Crontab.CronExpression.t()
  @callback get_time_zone() :: Timex.TimezoneInfo.t()
  @callback get_time_slot(DateTime.t()) :: time_slot()
  @callback get_airing_time(DateTime.t()) :: DateTime.t() | {:error, atom()}
  @callback get_occurrence_at(DateTime.t()) :: any()
  @callback get_slices_from_occurrence(MediaWatch.Analysis.ShowOccurrence.t()) :: [any()]
  @callback create_occurrence(any()) :: any()
  @callback create_occurrence_and_store(any(), Ecto.Repo.t()) :: any()
  @callback update_occurrence(any(), used :: [any()], discarded :: [any()], new :: [any()]) ::
              any()
  @callback update_occurrence_and_store(any(), any(), Ecto.Repo.t()) :: any()

  defmacro __using__(_opts) do
    quote do
      @behaviour MediaWatch.Analysis.Recurrent

      @impl true
      def get_time_slot(dt),
        do: get_airing_schedule() |> MediaWatch.Schedule.get_time_slot!(dt |> to_time_zone)

      @impl true
      def get_time_zone(), do: "Europe/Paris" |> Timex.Timezone.get()

      @impl true
      def get_airing_time(dt),
        do: get_airing_schedule() |> MediaWatch.Schedule.get_airing_time(dt |> to_time_zone)

      @impl true
      def create_occurrence_and_store(slice, repo),
        do:
          slice
          |> create_occurrence()
          |> MediaWatch.Repo.insert_and_retry(repo)
          |> explain_error()

      @impl true
      def update_occurrence_and_store(occ, slice, repo) do
        all_slices = get_slices_from_occurrence(occ) ++ [slice]
        grouped = group_slices(occ, all_slices)

        occ
        |> repo.preload(:show)
        |> update_occurrence(
          grouped |> Map.get(:used, []),
          grouped |> Map.get(:discarded, []),
          grouped |> Map.get(:new, [])
        )
        |> MediaWatch.Repo.update_and_retry(repo)
      end

      defp group_slices(occ, slices) do
        slices
        |> Enum.group_by(&{&1.id in occ.slices_used, &1.id in occ.slices_discarded})
        |> Map.new(fn
          {{true, false}, v} -> {:used, v}
          {{false, true}, v} -> {:discarded, v}
          {{false, false}, v} -> {:new, v}
        end)
      end

      defp to_time_zone(dt), do: dt |> Timex.Timezone.convert(get_time_zone())

      defp explain_error(
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
        with {_, airing_time} <- cs |> Ecto.Changeset.fetch_field(:airing_time),
             occ <- airing_time |> get_occurrence_at() do
          {:error, {:unique_airing_time, occ}}
        else
          _ -> {:error, :unique_airing_time}
        end
      end

      defp explain_error(
             {:error,
              cs = %{errors: [airing_time: {_, [type: :utc_datetime, validation: :cast]}]}}
           ),
           do: {:error, :no_airing_time_within_slot}

      defp explain_error(res), do: res

      defoverridable create_occurrence_and_store: 2
    end
  end
end
