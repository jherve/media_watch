defmodule MediaWatch.Repo.Migrations.AddSlices do
  use Ecto.Migration

  def change do
    create table(:slices) do
      add :type, :string, null: false
      add :kind, :string

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
             where: "type = 'open_graph'",
             name: :slices_open_graphs_index
           )

    create table(:slices_rss_entries, primary_key: false) do
      add :id, references(:slices, column: :id, on_delete: :delete_all), primary_key: true

      add :guid, :string, null: false
      add :title, :string, null: false
      add :description, :string, null: false
      add :link, :string
      add :pub_date, :utc_datetime, null: false
    end

    create unique_index(:slices_rss_entries, [:guid])

    create table(:slices_rss_channel_descriptions, primary_key: false) do
      add :id, references(:slices, column: :id, on_delete: :delete_all), primary_key: true

      add :title, :string, null: false
      add :description, :string, null: false
      add :link, :string
      add :image, :map
    end

    create table(:slices_html_preview_cards, primary_key: false) do
      add :id, references(:slices, column: :id, on_delete: :delete_all), primary_key: true

      add :title, :string, null: false
      # TODO: This field should eventually be removed, but it a bit more work as it is
      # used as one of the components of the unique index for this table
      add :type, :string, null: false, default: "unknown"
      add :text, :string
      add :link, :string
      add :image, :map
      add :date, :utc_datetime, null: false
    end

    create unique_index(:slices_html_preview_cards, [:title, :date, :type])

    create table(:slices_open_graphs, primary_key: false) do
      add :id, references(:slices, column: :id, on_delete: :delete_all), primary_key: true

      add :title, :string, null: false
      add :type, :string
      add :url, :string, null: false
      add :image, :string, null: false
      add :description, :string
    end
  end
end
