defmodule MediaWatch.Repo.Migrations.AddSnapshotStrategies do
  use Ecto.Migration

  def change do
    create table(:snapshot_strategies) do
      add :watched_item_id, references(:watched_items, column: :id), null: false
    end

    create table(:rss_feeds, primary_key: false) do
      add :id, references(:snapshot_strategies, column: :id), primary_key: true
      add :url, :string, null: false
    end

    create unique_index(:rss_feeds, [:url])
  end
end
