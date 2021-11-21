defmodule MediaWatch.Repo.Migrations.AddGuests do
  use Ecto.Migration

  def change do
    create table(:persons) do
      add :wikidata_qid, :id

      add :label, :string, null: false
      add :description, :string
    end

    create unique_index(:persons, [:wikidata_qid], where: "wikidata_qid IS NOT NULL")
    create unique_index(:persons, [:label], where: "wikidata_qid IS NULL")

    create table(:show_occurrences_invitations) do
      add :person_id, references(:persons, column: :id, on_delete: :delete_all)
      add :show_occurrence_id, references(:show_occurrences, column: :id, on_delete: :delete_all)
    end

    create unique_index(:show_occurrences_invitations, [:person_id, :show_occurrence_id])
  end
end
