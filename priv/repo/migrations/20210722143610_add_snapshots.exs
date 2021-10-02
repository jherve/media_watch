defmodule MediaWatch.Repo.Migrations.AddSnapshots do
  use Ecto.Migration

  def change do
    create table(:snapshots) do
      add :source_id, references(:sources, column: :id, on_delete: :delete_all)
      add :type, :string, null: false
      timestamps(type: :utc_datetime)
    end

    create table(:snapshots_xml, primary_key: false) do
      add :id, references(:snapshots, column: :id, on_delete: :delete_all), primary_key: true
      add :content, :string, null: false
    end

    # This should ideally be a trigger that checks uniqueness on content + source_id
    # (from snapshots table) but it's highly unlikely that two distinct sources
    # produce exactly the same snapshot.
    create unique_index(:snapshots_xml, [:content])
  end
end
