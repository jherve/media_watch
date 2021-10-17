defmodule MediaWatch.Repo.Migrations.AddWatchedItems do
  use Ecto.Migration

  def change do
    create table(:catalog_channels) do
      add :module, :string, null: false
      add :name, :string, null: false
      add :url, :string, null: false
    end

    create unique_index(:catalog_channels, [:module])

    create table(:catalog_items) do
      add :module, :string
    end

    create unique_index(:catalog_items, [:module])

    create table(:channel_items, primary_key: false) do
      add :channel_id, references(:catalog_channels, column: :id, on_delete: :delete_all),
        primary_key: true

      add :item_id, references(:catalog_items, column: :id, on_delete: :delete_all),
        primary_key: true
    end

    create table(:catalog_shows, primary_key: false) do
      add :id, references(:catalog_items, column: :id, on_delete: :delete_all), primary_key: true
      add :name, :string, null: false
      add :url, :string, null: false
      add :airing_schedule, :map, null: false
      add :duration_minutes, :integer, null: false
      add :host_names, {:array, :string}, null: false
      add :alternate_hosts, {:array, :string}, default: []
    end

    create unique_index(:catalog_shows, [:name, :url])
  end
end
