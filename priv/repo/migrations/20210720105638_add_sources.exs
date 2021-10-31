defmodule MediaWatch.Repo.Migrations.AddSources do
  use Ecto.Migration

  def change do
    create table(:catalog_sources) do
      add :item_id, references(:catalog_items, column: :id, on_delete: :delete_all), null: false
      add :type, :string, null: false
    end

    create table(:catalog_rss_feeds, primary_key: false) do
      add :id, references(:catalog_sources, column: :id, on_delete: :delete_all),
        primary_key: true

      add :url, :string, null: false
    end

    create unique_index(:catalog_rss_feeds, [:url])

    create table(:catalog_web_index_pages, primary_key: false) do
      add :id, references(:catalog_sources, column: :id, on_delete: :delete_all),
        primary_key: true

      add :url, :string, null: false
    end

    create unique_index(:catalog_web_index_pages, [:url])
  end
end
