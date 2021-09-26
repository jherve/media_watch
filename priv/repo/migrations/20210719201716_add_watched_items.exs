defmodule MediaWatch.Repo.Migrations.AddWatchedItems do
  use Ecto.Migration

  def change do
    create table(:channels) do
      add :name, :string, null: false
      add :url, :string, null: false
    end

    create unique_index(:channels, [:name])

    create table(:watched_items) do
      add :module, :string
    end

    create table(:channel_items, primary_key: false) do
      add :channel_id, references(:channels, column: :id), primary_key: true
      add :item_id, references(:watched_items, column: :id), primary_key: true
    end

    create table(:watched_shows, primary_key: false) do
      add :id, references(:watched_items, column: :id), primary_key: true
      add :name, :string, null: false
      add :url, :string, null: false
    end

    create unique_index(:watched_shows, [:name, :url])
  end
end
