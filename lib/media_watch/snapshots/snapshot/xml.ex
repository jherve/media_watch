defmodule MediaWatch.Snapshots.Snapshot.Xml do
  use Ecto.Schema
  import Ecto.Changeset
  alias __MODULE__, as: Xml

  schema "snapshots_xml" do
    field :content, :string
  end

  @doc false
  def changeset(xml \\ %Xml{}, attrs) do
    xml
    |> cast(attrs, [:content])
    |> validate_required([:content])
  end
end
