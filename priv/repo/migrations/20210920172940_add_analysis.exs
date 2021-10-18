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
    end

    create table(:show_occurrences) do
      add :show_id, references(:catalog_shows, column: :id, on_delete: :delete_all), null: false

      add :title, :string, null: false
      add :description, :string, null: false
      add :link, :string
      add :airing_time, :utc_datetime, null: false
      add :slot_start, :utc_datetime, null: false
      add :slot_end, :utc_datetime, null: false
    end

    create unique_index(:show_occurrences, [:show_id, :airing_time])

    create table(:slices_usages) do
      add :show_occurrence_id, references(:show_occurrences, column: :id, on_delete: :delete_all),
        check: %{
          name: "slices_usages_only_one_of",
          expr: """
          (show_occurrence_id IS NOT NULL AND description_id IS NULL)
            OR (show_occurrence_id IS NULL AND description_id IS NOT NULL)
          """
        }

      add :description_id, references(:descriptions, column: :item_id, on_delete: :delete_all)
      add :slice_id, references(:slices, column: :id, on_delete: :delete_all), null: false
      add :used, :boolean, null: false
    end

    create unique_index(:slices_usages, [:show_occurrence_id, :slice_id],
             where: "show_occurrence_id IS NOT NULL"
           )

    create unique_index(:slices_usages, [:description_id, :slice_id],
             where: "description_id IS NOT NULL"
           )
  end
end
