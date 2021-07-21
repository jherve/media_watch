defmodule MediaWatch.Catalog do
  alias MediaWatch.Repo
  alias MediaWatch.Catalog.Show

  def list_all(), do: Show |> Repo.all()
end
