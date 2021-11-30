defmodule MediaWatch.Parsing.Slice.OpenGraph do
  use Ecto.Schema
  import Ecto.Changeset
  alias __MODULE__
  @required_fields [:title, :url, :image]
  @optional_fields [:type, :description]
  @all_fields @required_fields ++ @optional_fields

  schema "slices_open_graphs" do
    field :title, :string
    field :type, :string
    field :url, :string
    field :image, :string
    field :description, :string
  end

  @doc false
  def changeset(graph \\ %OpenGraph{}, attrs) do
    graph
    |> cast(attrs, @all_fields)
    |> validate_required(@required_fields)
  end

  def get_list_of_attributes(parsed) when is_list(parsed) do
    %{
      image: get_open_graph_property(parsed, :image),
      title: get_open_graph_property(parsed, :title),
      description: get_open_graph_property(parsed, :description),
      url: get_open_graph_property(parsed, :url),
      type: get_open_graph_property(parsed, :type)
    }
  end

  defp get_open_graph_property(parsed, prop),
    do: parsed |> Floki.attribute("meta[property=\"og:#{prop}\"]", "content") |> List.first()
end
