defmodule MediaWatch.Repo.Migrations.AddParsedSnapshots do
  use Ecto.Migration

  def change do
    create table(:parsed_snapshots) do
      add :snapshot_id, references(:snapshots, column: :id, name: :id, on_delete: :nilify_all)

      add :source_id, references(:catalog_sources, column: :id, on_delete: :delete_all),
        null: false

      add :data, :map, null: false
      timestamps(type: :utc_datetime)
    end

    create unique_index(:parsed_snapshots, [:snapshot_id], where: "snapshot_id IS NOT NULL")
  end
end
