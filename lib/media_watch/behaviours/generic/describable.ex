defmodule MediaWatch.Analysis.Describable.Generic do
  @behaviour MediaWatch.Analysis.Describable
  alias MediaWatch.Parsing.Slice

  def get_description_attrs(item_id, %Slice{
        type: :rss_channel_description,
        rss_channel_description: desc
      }),
      do: %{
        item_id: item_id,
        title: desc.title,
        description: desc.description,
        link: desc.link,
        image: desc.image
      }

  def get_description_attrs(item_id, %Slice{
        type: :open_graph,
        open_graph: graph
      }),
      do: %{
        item_id: item_id,
        title: graph.title,
        description: graph.description,
        link: graph.url,
        image: %{"url" => graph.image}
      }

  defmacro __using__(_opts) do
    quote do
      alias MediaWatch.Analysis.Describable

      @impl Describable
      defdelegate get_description_attrs(item_id, slice), to: Describable.Generic

      defoverridable get_description_attrs: 2
    end
  end
end
