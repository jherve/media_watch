defmodule MediaWatch.Utils do
  import Ecto.Changeset
  alias MediaWatch.Repo
  alias MediaWatch.Catalog.{Channel, Item}
  alias MediaWatch.Catalog.Person

  @doc "Attempt to display a friendlier message for certain types of errors"
  @spec inspect_error(any()) :: binary()
  def inspect_error(e = %Ecto.Changeset{data: %struct{}}),
    do:
      "#{struct} changeset has errors : #{e |> traverse_errors(fn {msg, _opts} -> msg end) |> inspect}"

  def inspect_error(e), do: inspect(e)

  @doc "Restart the whole catalog supervisor"
  def restart_catalog(), do: Supervisor.stop(MediaWatch.Catalog.CatalogSupervisor)

  @doc "Remove all items from the database"
  def nuke_database() do
    Channel |> Repo.delete_all()
    Item |> Repo.delete_all()
    Person |> Repo.delete_all()
  end
end
