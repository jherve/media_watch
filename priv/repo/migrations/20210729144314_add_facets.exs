defmodule MediaWatch.Repo.Migrations.AddFacets do
  use Ecto.Migration

  def change do
    create table(:facets) do
      add :source_id, references(:sources, column: :id), null: false
      add :parsed_snapshot_id, references(:parsed_snapshots, column: :id), null: false
      add :date_start, :utc_datetime, null: false
      add :date_end, :utc_datetime, null: false

      timestamps(type: :utc_datetime)
    end

    create table(:show_occurrences, primary_key: false) do
      add :id, references(:facets, column: :id), primary_key: true

      add :title, :string, null: false
      add :description, :string, null: false
      add :url, :string, null: false
    end
  end
end
