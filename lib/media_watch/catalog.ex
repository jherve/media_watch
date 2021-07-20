defmodule MediaWatch.Catalog do
  alias MediaWatch.Repo
  alias MediaWatch.Catalog.Podcast

  def list_all(), do: Podcast |> Repo.all()
end
