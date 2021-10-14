defmodule MediaWatch.Repo.Migrations.AddParsedSnapshots do
  use Ecto.Migration

  def change do
    create table(:parsed_snapshots, primary_key: false) do
      add :id, references(:snapshots, column: :id, name: :id, on_delete: :delete_all),
        primary_key: true

      add :source_id, references(:sources, column: :id, on_delete: :delete_all), null: false

      add :data, :map, null: false
      timestamps(type: :utc_datetime)
    end
  end
end
