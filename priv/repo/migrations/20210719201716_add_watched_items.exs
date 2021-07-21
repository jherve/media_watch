defmodule MediaWatch.Repo.Migrations.AddWatchedItems do
  use Ecto.Migration

  def change do
    create table(:watched_items) do
    end

    create table(:watched_shows, primary_key: false) do
      add :id, references(:watched_items, column: :id), primary_key: true
      add :name, :string, null: false
      add :url, :string, null: false
    end

    create unique_index(:watched_shows, [:name, :url])
  end
end
