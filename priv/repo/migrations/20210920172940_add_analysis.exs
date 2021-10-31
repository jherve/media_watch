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
      add :airing_time, :utc_datetime, null: false
      add :slot_start, :utc_datetime, null: false
      add :slot_end, :utc_datetime, null: false
    end

    create unique_index(:show_occurrences, [:show_id, :airing_time])

    create table(:show_occurrences_details, primary_key: false) do
      add :id, references(:show_occurrences, column: :id, on_delete: :delete_all),
        primary_key: true

      add :title, :string, null: false
      add :description, :string
      add :link, :string
    end

    create table(:slices_usages) do
      add :show_occurrence_id, references(:show_occurrences, column: :id, on_delete: :delete_all),
        check: %{
          name: "slices_usages_show_occurrence_id_when_occurrence",
          expr: """
          (type = 'show_occurrence_description' OR type = 'show_occurrence_excerpt' AND show_occurrence_id IS NOT NULL)
            OR (type != 'show_occurrence_description' AND type != 'show_occurrence_excerpt')
          """
        }

      add :description_id, references(:descriptions, column: :item_id, on_delete: :delete_all),
        check: %{
          name: "slices_usages_description_id_when_item_description",
          expr: """
          (type = 'item_description' AND description_id IS NOT NULL)
            OR type != 'item_description'
          """
        }

      add :slice_id, references(:slices, column: :id, on_delete: :delete_all), null: false
      add :type, :string, null: false
    end

    create unique_index(:slices_usages, [:show_occurrence_id, :slice_id],
             where: "show_occurrence_id IS NOT NULL"
           )

    create unique_index(:slices_usages, [:description_id, :slice_id],
             where: "description_id IS NOT NULL"
           )
  end
end
