defmodule MediaWatch.Repo.Migrations.AddSlices do
  use Ecto.Migration

  def change do
    create table(:slices) do
      add :type, :string, null: false

      add :source_id, references(:sources, column: :id), null: false
      add :parsed_snapshot_id, references(:parsed_snapshots, column: :id), null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:slices, [:source_id],
             where: "type = 'rss_channel_description'",
             name: :slices_rss_channel_descriptions_index
           )

    create table(:rss_entries, primary_key: false) do
      add :id, references(:slices, column: :id), primary_key: true

      add :guid, :string, null: false
      add :title, :string, null: false
      add :description, :string, null: false
      add :link, :string
      add :pub_date, :utc_datetime, null: false
    end

    create unique_index(:rss_entries, [:guid])

    create table(:rss_channel_descriptions, primary_key: false) do
      add :id, references(:slices, column: :id), primary_key: true

      add :title, :string, null: false
      add :description, :string, null: false
      add :link, :string
      add :image, :map
    end
  end
end
