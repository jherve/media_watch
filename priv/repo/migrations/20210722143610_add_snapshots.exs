defmodule MediaWatch.Repo.Migrations.AddSnapshots do
  use Ecto.Migration

  def change do
    create table(:snapshots) do
      add :source_id, references(:catalog_sources, column: :id, on_delete: :delete_all)
      add :url, :string, null: false
      add :type, :string, null: false
      add :content_hash, :string, null: false
      timestamps(type: :utc_datetime)
    end

    create unique_index(:snapshots, [:source_id, :content_hash])

    create table(:snapshots_xml, primary_key: false) do
      add :id, references(:snapshots, column: :id, on_delete: :delete_all), primary_key: true
      add :content, :string, null: false
    end

    create table(:snapshots_html, primary_key: false) do
      add :id, references(:snapshots, column: :id, on_delete: :delete_all), primary_key: true
      add :content, :string, null: false
    end
  end
end
