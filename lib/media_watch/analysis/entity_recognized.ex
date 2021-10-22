defmodule MediaWatch.Analysis.EntityRecognized do
  use Ecto.Schema
  import Ecto.Changeset
  alias MediaWatch.Repo
  alias MediaWatch.Parsing.Slice
  alias MediaWatch.Spacy
  alias __MODULE__, as: EntityRecognized
  @required_fields [:label, :type, :field]
  @all_fields @required_fields

  schema "entities_recognized" do
    field :label, :string
    field :type, :string
    field :field, :string
    belongs_to :slice, Slice
  end

  @doc false
  def changeset(entity \\ %EntityRecognized{}, attrs) do
    entity
    |> cast(attrs, @all_fields)
    |> cast_assoc(:slice, required: true)
    |> validate_required(@required_fields)
    |> unique_constraint([:slice_id, :label, :type, :field])
  end

  def get_entities_cs(
        slice = %Slice{
          type: :rss_channel_description,
          rss_channel_description: %{title: title, description: desc}
        }
      ),
      do: get_entities_cs(slice, title, desc)

  def get_entities_cs(
        slice = %Slice{type: :rss_entry, rss_entry: %{title: title, description: desc}}
      ),
      do: get_entities_cs(slice, title, desc)

  def get_entities_cs(slice = %Slice{}, title, desc) do
    with {:ok, title_list} <- Spacy.extract_entities(title),
         {:ok, desc_list} <- Spacy.extract_entities(desc) do
      (title_list |> into_cs_list(slice, "title")) ++
        (desc_list |> into_cs_list(slice, "description"))
    end
  end

  def insert_entities(cs_list) when is_list(cs_list) do
    with {:ok, res} <-
           Repo.transaction(fn _ ->
             cs_list |> Enum.map(&Repo.insert_and_retry(&1))
           end),
         do: res
  end

  def maybe_filter(cs_list, recognisable) when is_list(cs_list),
    do: cs_list |> Enum.reject(&maybe_blacklist(&1, recognisable))

  defp into_cs_list(name_list, slice, field) when is_list(name_list) do
    name_list
    |> Enum.uniq()
    |> Enum.map(
      &changeset(%EntityRecognized{slice: slice}, %{type: "PER", label: &1, field: field})
    )
  end

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
