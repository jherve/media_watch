defmodule MediaWatch.Utils do
  import Ecto.Changeset

  @doc "Attempt to display a friendlier message for certain types of errors"
  @spec inspect_error(any()) :: binary()
  def inspect_error(e = %Ecto.Changeset{data: %struct{}}),
    do:
      "#{struct} changeset has errors : #{e |> traverse_errors(fn {msg, _opts} -> msg end) |> inspect}"

  def inspect_error(e), do: inspect(e)
end
