defmodule MediaWatch.Analysis.Slice.RssChannelDescription do
  use Ecto.Schema
  import Ecto.Changeset
  alias __MODULE__, as: RssChannelDescription
  @all_fields [:title, :description, :link, :image]
  @required_fields [:title, :description]

  schema "rss_channel_descriptions" do
    field :title, :string
    field :description, :string
    field :link, :string
    field :image, :map
  end

  @doc false
  def changeset(desc \\ %RssChannelDescription{}, attrs) do
    desc
    |> cast(attrs, @all_fields)
    |> validate_required(@required_fields)
  end
end
