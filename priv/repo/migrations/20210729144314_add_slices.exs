defmodule MediaWatch.Repo.Migrations.AddSlices do
  use Ecto.Migration

  def change do
    create table(:slices) do
      add :type, :string, null: false

      add :source_id, references(:catalog_sources, column: :id, on_delete: :delete_all),
        null: false

      add :parsed_snapshot_id, references(:parsed_snapshots, column: :id, on_delete: :nilify_all)

      timestamps(type: :utc_datetime)
    end

    create unique_index(:slices, [:source_id],
             where: "type = 'rss_channel_description'",
             name: :slices_rss_channel_descriptions_index
           )

    create unique_index(:slices, [:source_id],
             where: "type = 'html_header'",
             name: :slices_html_headers_index
           )

    create table(:rss_entries, primary_key: false) do
      add :id, references(:slices, column: :id, on_delete: :delete_all), primary_key: true

      add :guid, :string, null: false
      add :title, :string, null: false
      add :description, :string, null: false
      add :link, :string
      add :pub_date, :utc_datetime, null: false
    end

    create unique_index(:rss_entries, [:guid])

    create table(:rss_channel_descriptions, primary_key: false) do
      add :id, references(:slices, column: :id, on_delete: :delete_all), primary_key: true

      add :title, :string, null: false
      add :description, :string, null: false
      add :link, :string
      add :image, :map
    end

    create table(:html_list_items, primary_key: false) do
      add :id, references(:slices, column: :id, on_delete: :delete_all), primary_key: true

      add :title, :string, null: false
      add :text, :string
      add :link, :string
      add :image, :map
      add :date, :utc_datetime, null: false
    end

    create unique_index(:html_list_items, [:title, :date])

    create table(:html_headers, primary_key: false) do
      add :id, references(:slices, column: :id, on_delete: :delete_all), primary_key: true

      add :title, :string, null: false
      add :description, :string, null: false
      add :link, :string
      add :image, :map
    end
  end
end
