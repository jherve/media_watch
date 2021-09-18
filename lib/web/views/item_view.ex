defmodule MediaWatchWeb.ItemView do
  use MediaWatchWeb, :view

  def item_title(item),
    do: ~E"""
      <%= item.show.name %> (<%= item.channels |> Enum.map(& &1.name) |> Enum.join(", ") %>)
    """
end
