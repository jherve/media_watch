defmodule Ecto.MapWithTuple do
  use Ecto.Type
  alias Jason.Encoder

  defimpl Encoder, for: Tuple do
    def encode(data, options) when is_tuple(data) do
      %{"tuple" => data |> Tuple.to_list()}
      |> Encoder.encode(options)
    end
  end

  def type, do: :map

  def cast(map) when is_map(map), do: {:ok, map}
  def cast(_), do: :error

  def load(data) when is_map(data), do: {:ok, data |> convert_nodes_to_tuples()}

  defp convert_nodes_to_tuples(%{"tuple" => list}) when is_list(list),
    do: list |> convert_nodes_to_tuples |> List.to_tuple()

  defp convert_nodes_to_tuples(list) when is_list(list),
    do: list |> Enum.map(&convert_nodes_to_tuples/1)

  defp convert_nodes_to_tuples(map) when is_map(map),
    do: map |> Map.new(fn {k, v} -> {k, v |> convert_nodes_to_tuples()} end)

  defp convert_nodes_to_tuples(other), do: other

  def dump(map) when is_map(map), do: {:ok, map}
  def dump(_), do: :error
end
