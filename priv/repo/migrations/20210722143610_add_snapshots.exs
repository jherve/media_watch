defmodule MediaWatch.Repo.Migrations.AddSnapshots do
  use Ecto.Migration

  def change do
    create table(:snapshots) do
      add :source_id, references(:sources, column: :id)
      timestamps(type: :utc_datetime)
    end

    create table(:snapshots_xml, primary_key: false) do
      add :id, references(:snapshots, column: :id), primary_key: true
      add :content, :string, null: false
    end
  end
end
