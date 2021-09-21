defmodule MediaWatch.Repo.Migrations.AddAnalysis do
  use Ecto.Migration

  def change do
    create table(:descriptions, primary_key: false) do
      add :id, references(:watched_items, column: :id), primary_key: true

      add :title, :string, null: false
      add :description, :string, null: false
      add :link, :string
      add :image, :map

      add :slice_ids, {:array, :id}
    end

    create table(:show_occurrences) do
      add :show_id, references(:watched_shows, column: :id), null: false

      add :title, :string, null: false
      add :description, :string, null: false
      add :link, :string
      add :date_start, :utc_datetime, null: false

      add :slice_ids, {:array, :id}
    end

    create unique_index(:show_occurrences, [:show_id, :date_start])
  end
end
