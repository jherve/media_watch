defmodule MediaWatch.Analysis.Slice do
  use Ecto.Schema
  import Ecto.Changeset
  alias MediaWatch.Catalog.Source
  alias MediaWatch.Parsing.ParsedSnapshot
  alias MediaWatch.Analysis.Slice.{RssEntry, RssChannelDescription}
  alias __MODULE__, as: Slice

  schema "slices" do
    belongs_to :source, Source
    belongs_to :parsed_snapshot, ParsedSnapshot
    has_one :rss_entry, RssEntry, foreign_key: :id
    has_one :rss_channel_description, RssChannelDescription, foreign_key: :id

    Ecto.Schema.timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(slice \\ %Slice{}, attrs) do
    slice
    |> cast(attrs, [:id])
    |> cast_assoc(:parsed_snapshot, required: true)
    |> cast_assoc(:source, required: true)
    |> cast_assoc(:rss_entry)
    |> cast_assoc(:rss_channel_description)
  end
end
