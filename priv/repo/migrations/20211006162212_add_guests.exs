defmodule MediaWatch.Repo.Migrations.AddGuests do
  use Ecto.Migration

  def change do
    create table(:persons) do
      add :wikidata_qid, :id

      add :label, :string
      add :description, :string
    end

    create unique_index(:persons, [:wikidata_qid], where: "wikidata_qid IS NOT NULL")
    create unique_index(:persons, [:label], where: "wikidata_qid IS NULL")

    create table(:show_occurrences_invitations, primary_key: false) do
      add :person_id, references(:persons, column: :id, on_delete: :delete_all), primary_key: true

      add :show_occurrence_id, references(:show_occurrences, column: :id, on_delete: :delete_all),
        primary_key: true
    end
  end
end
