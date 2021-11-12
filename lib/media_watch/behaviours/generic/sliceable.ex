defmodule MediaWatch.Parsing.Sliceable.Generic do
  @behaviour MediaWatch.Parsing.Sliceable
  alias MediaWatch.Parsing.{ParsedSnapshot, Slice}
  alias MediaWatch.Catalog.Source.RssFeed

  def into_slice_cs(attrs, parsed = %ParsedSnapshot{snapshot: %{source: source}})
      when not is_nil(source) and not is_struct(source, Ecto.Association.NotLoaded) do
    Slice.changeset(%Slice{parsed_snapshot: parsed, source: source}, attrs)
  end

  def into_list_of_slice_attrs(%ParsedSnapshot{
        data: data,
        snapshot: %{source: %{type: :rss_feed}}
      }),
      do: data |> RssFeed.into_list_of_slice_attrs()

  def into_list_of_slice_attrs(%ParsedSnapshot{snapshot: %{source: %{type: :web_index_page}}}),
    do: raise("A custom implementation must be provided for web_index_page snapshots")

  defmacro __using__(_opts) do
    quote do
      alias MediaWatch.Parsing.Sliceable

      @impl Sliceable
      defdelegate into_list_of_slice_attrs(parsed), to: Sliceable.Generic

      @impl Sliceable
      defdelegate into_slice_cs(attrs, parsed), to: Sliceable.Generic

      defoverridable into_slice_cs: 2, into_list_of_slice_attrs: 1
    end
  end
end
