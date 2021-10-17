defmodule MediaWatch.Repo.Migrations.AddEntities do
  use Ecto.Migration

  def change do
    create table(:entities_recognized) do
      add :slice_id, references(:slices, column: :id, on_delete: :delete_all)
      add :label, :string, null: false
      add :type, :string, null: false
      add :field, :string, null: false
    end

    create unique_index(:entities_recognized, [:slice_id, :label, :type, :field])
  end
end
