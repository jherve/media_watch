defmodule MediaWatch.Repo.Migrations.AddAnalysis do
  use Ecto.Migration

  def change do
    create table(:descriptions, primary_key: false) do
      add :item_id, references(:catalog_items, column: :id, on_delete: :delete_all),
        primary_key: true

      add :title, :string, null: false
      add :description, :string, null: false
      add :link, :string
      add :image, :map

      add :slices_used, {:array, :id}, null: false
      add :slices_discarded, {:array, :id}, default: []
    end

    create table(:show_occurrences) do
      add :show_id, references(:catalog_shows, column: :id, on_delete: :delete_all), null: false

      add :title, :string, null: false
      add :description, :string, null: false
      add :link, :string
      add :airing_time, :utc_datetime, null: false
      add :slot_start, :utc_datetime, null: false
      add :slot_end, :utc_datetime, null: false

      add :slices_used, {:array, :id}, null: false
      add :slices_discarded, {:array, :id}, default: []
    end

    create unique_index(:show_occurrences, [:show_id, :airing_time])
  end
end
