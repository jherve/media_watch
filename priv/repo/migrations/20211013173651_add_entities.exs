defmodule MediaWatch.Repo.Migrations.AddEntities do
  use Ecto.Migration

  def change do
    create table(:entities_recognized) do
      add :slice_id, references(:slices, column: :id, on_delete: :delete_all)
      add :label, :string, null: false
      add :type, :string, null: false
      add :location_in_slice, :string, null: false
    end

    create unique_index(:entities_recognized, [:slice_id, :label, :type, :location_in_slice])
  end
end
