defmodule MediaWatch.Repo.Migrations.AddSources do
  use Ecto.Migration

  def change do
    create table(:sources) do
      add :item_id, references(:watched_items, column: :id), null: false
      add :type, :string, null: false
    end

    create table(:rss_feeds, primary_key: false) do
      add :id, references(:sources, column: :id), primary_key: true
      add :url, :string, null: false
    end

    create unique_index(:rss_feeds, [:url])
  end
end
