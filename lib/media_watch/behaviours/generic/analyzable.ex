defmodule MediaWatch.Analysis.Analyzable.Generic do
  @behaviour MediaWatch.Analysis.Analyzable
  alias MediaWatch.Parsing.Slice

  def classify(%Slice{type: :rss_channel_description}), do: :item_description
  def classify(%Slice{type: :rss_entry}), do: :show_occurrence_description

  def classify(%Slice{type: :html_preview_card, html_preview_card: %{type: card_type}})
      when card_type in [:excerpt, :excerpt_short],
      do: :show_occurrence_excerpt

  def classify(%Slice{type: :html_preview_card, html_preview_card: %{type: _}}),
    do: :show_occurrence_description

  def classify(%Slice{type: :open_graph}), do: :item_description

  defmacro __using__(_opts) do
    quote do
      alias MediaWatch.Analysis.Analyzable

      @impl Analyzable
      defdelegate classify(slice), to: Analyzable.Generic

      defoverridable classify: 1
    end
  end
end
