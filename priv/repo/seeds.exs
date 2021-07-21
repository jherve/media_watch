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
  alias MediaWatch.Catalog.{Item, Show}

  def as_item(show = %Show{}), do: %Item{show: show}

  def insert(item) do
    with {:ok, inserted} <- item |> Repo.insert(), do: inserted
  rescue
    e in Ecto.ConstraintError ->
      if e.type == :unique, do: Logger.warning("#{inspect(item)} already inserted")
  end
end

alias MediaWatch.Catalog.{Item, Show}
alias MediaWatch.Repo

[
  %Show{name: "L'invité de 8h20'", url: "https://www.franceinter.fr/emissions/l-invite"},
  %Show{name: "L'invité de RTL", url: "https://www.rtl.fr/programmes/l-invite-de-rtl"}
]
|> Enum.map(&Utils.as_item/1)
|> Enum.each(&Utils.insert/1)
