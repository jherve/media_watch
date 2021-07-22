defmodule MediaWatch.Snapshots.Snapshot do
  use Ecto.Schema
  import Ecto.Changeset
  alias MediaWatch.Catalog.Source
  alias __MODULE__, as: Snapshot

  schema "snapshots" do
    belongs_to :source, Source
    Ecto.Schema.timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(snapshot \\ %Snapshot{}, attrs) do
    snapshot
    |> cast(attrs, [:id])
    |> cast_assoc(:source, required: true)
  end
end
