defmodule MediaWatch.Parsing.Parsable.Generic do
  @behaviour MediaWatch.Parsing.Parsable

  alias MediaWatch.Snapshots.Snapshot
  alias MediaWatch.Snapshots.Snapshot.{Xml, Html}

  def parse_snapshot(%Snapshot{type: :xml, xml: xml}), do: xml |> Xml.parse_snapshot()
  def parse_snapshot(%Snapshot{type: :html, html: html}), do: html |> Html.parse_snapshot()

  def prune_snapshot(parsed, %Snapshot{type: :xml}), do: parsed |> Xml.prune_snapshot()

  def prune_snapshot(_, %Snapshot{type: :html}),
    do: raise("A custom implementation must be provided for html snapshots")

  defmacro __using__(_opts) do
    quote do
      alias MediaWatch.Parsing.Parsable
      @behaviour Parsable

      @impl Parsable
      defdelegate parse_snapshot(snap), to: Parsable.Generic

      @impl Parsable
      defdelegate prune_snapshot(data, snap), to: Parsable.Generic

      defoverridable parse_snapshot: 1, prune_snapshot: 2
    end
  end
end
