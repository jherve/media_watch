defmodule MediaWatch.Catalog do
  alias MediaWatch.Repo
  alias MediaWatch.Catalog.Item

  def list_all(), do: Item |> Repo.all() |> Repo.preload([:show, strategies: :rss_feed])
end
