defmodule MediaWatch.Analysis do
  import Ecto.Query
  alias Ecto.Multi
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

  alias MediaWatch.Actions.GuestAddition

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

  def run_occurrence_pipeline(slice, module),
    do:
      OccurrenceSliceAnalysisPipeline.new(slice, module)
      |> OccurrenceSliceAnalysisPipeline.run()

  def run_description_pipeline(slice, module),
    do:
      DescriptionSliceAnalysisPipeline.new(slice, module)
      |> DescriptionSliceAnalysisPipeline.run()

  defdelegate recognize_entities(slice, module), to: EntityRecognitionServer
  defdelegate detect_occurrence(slice, module), to: ShowOccurrencesServer
  defdelegate add_details(occurrence, slice), to: ShowOccurrencesServer
  defdelegate do_guest_detection(occurrence, recognizable, hosted), to: ShowOccurrencesServer
  defdelegate do_description(slice, module), to: ItemDescriptionServer

  def delete_invitation(invitation, manual? \\ false)

  def delete_invitation(invitation = %Invitation{}, true),
    do:
      Multi.new()
      |> Multi.delete(:delete, invitation)
      |> ShowOccurrence.into_manual_multi(invitation.show_occurrence_id)
      |> do_delete_invitation()

  def delete_invitation(invitation = %Invitation{}, false),
    do:
      Multi.new()
      |> Multi.delete(:delete, invitation)
      |> do_delete_invitation()

  defp do_delete_invitation(multi = %Multi{}) do
    with {:ok, _} <- multi |> Repo.safe_transaction() do
      :ok
    else
      {:error, {:trigger, _, "show_occurrence_locked"}} -> {:error, :locked}
    end
  end

  def insert_invitation(invitation_cs, manual? \\ false, repo \\ Repo)

  def insert_invitation(invitation_cs = %Ecto.Changeset{}, manual? = false, repo) do
    case invitation_cs |> Invitation.set_manual_fields(manual?) |> repo.safe_insert() do
      ok = {:ok, _} ->
        ok

      e = {:error, _} ->
        e |> Invitation.rescue_error(repo) |> do_invitation_insertion_recovery(manual?, repo)
    end
  end

  def insert_invitation(invitation_cs = %Ecto.Changeset{}, manual? = true, repo) do
    invitation_cs = invitation_cs |> Invitation.set_manual_fields(manual?)

    show_occurrence_id =
      invitation_cs |> Ecto.Changeset.fetch_field!(:show_occurrence) |> Map.get(:id)

    with {:ok, %{insert: insert}} <-
           Multi.new()
           |> Multi.insert(:insert, invitation_cs)
           |> ShowOccurrence.into_manual_multi(show_occurrence_id)
           |> Repo.safe_transaction() do
      {:ok, insert}
    else
      {:error, :insert, error_cs, _} ->
        {:error, error_cs}
        |> Invitation.rescue_error(repo)
        |> do_invitation_insertion_recovery(manual?, repo)
    end
  end

  defp do_invitation_insertion_recovery({:error, {:unique, existing}}, _, _),
    do: {:already, existing}

  defp do_invitation_insertion_recovery({:error, {:person_exists, new_cs}}, manual?, repo),
    do: new_cs |> insert_invitation(manual?, repo)

  defp do_invitation_insertion_recovery(e = {:error, _}, _, _), do: e

  def changeset_for_guest_addition(show_occurrence = %ShowOccurrence{}, params \\ %{}) do
    %GuestAddition{show_occurrence: show_occurrence} |> GuestAddition.changeset(params)
  end

  def do_guest_addition(cs = %Ecto.Changeset{data: %GuestAddition{}}) do
    with {:ok, invitation_cs} <- cs |> GuestAddition.to_invitation_cs(),
         ok = {:ok, _} <- invitation_cs |> insert_invitation(true) do
      ok
    else
      {:already, _} ->
        cs
        |> Ecto.Changeset.add_error(:person_label, "Already exists")
        |> Ecto.Changeset.apply_action(:insert)

      e = {:error, %{data: %GuestAddition{}}} ->
        e

      {:error, _} ->
        cs
        |> Ecto.Changeset.add_error(:person_label, "Unknown error")
        |> Ecto.Changeset.apply_action(:insert)
    end
  end

  def confirm_invitation(invitation = %Invitation{}) do
    with {:ok, _} <-
           Multi.new()
           |> Multi.update(:update, invitation |> Ecto.Changeset.change(%{verified?: true}))
           |> ShowOccurrence.into_manual_multi(invitation.show_occurrence_id)
           |> Repo.safe_transaction(),
         do: :ok
  end
end
