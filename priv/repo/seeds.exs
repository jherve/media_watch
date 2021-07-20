# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     MediaWatch.Repo.insert!(%MediaWatch.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

defmodule Utils do
  require Logger
  alias MediaWatch.Repo
  alias MediaWatch.Catalog.{Item, Podcast}

  def podcast(attrs), do: struct(Podcast, attrs) |> Map.put(:item, %Item{id: nil})

  def insert(item) do
    with {:ok, inserted} <- item |> Repo.insert(), do: inserted
  rescue
    e in Ecto.ConstraintError ->
      if e.type == :unique, do: Logger.warning("#{inspect(item)} already inserted")
  end
end

alias MediaWatch.Repo

[
  %{name: "L'invité de 8h20'", url: "http://radiofrance-podcast.net/podcast09/rss_10239.xml"},
  %{name: "L'invité de RTL", url: "https://www.rtl.fr/podcast/linvite-de-rtl.xml"}
]
|> Enum.map(&Utils.podcast/1)
|> Enum.each(&Utils.insert/1)
