defmodule MediaWatchWeb.ItemIndexLive do
  use MediaWatchWeb, :live_view
  alias MediaWatch.Analysis
  alias MediaWatchWeb.Component.List
  alias MediaWatchWeb.ItemLiveComponent

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(
       page_title: "Liste des émissions",
       css_page_id: "item-index",
       items_by_channel:
         Analysis.get_all_analyzed_items()
         |> Enum.group_by(& &1.channels)
         |> Enum.flat_map(fn {chan_list, item} -> chan_list |> Enum.map(&{&1, item}) end)
     )}
  end

  @impl true
  def render(assigns),
    do: ~H"""
      <h1><%= @page_title %></h1>

      <%= for {channel, item_list} <- @items_by_channel do %>
        <h2><%= channel.name %></h2>

        <List.ul let={item} list={item_list}>
          <.live_component module={ItemLiveComponent} id={item.id} item={item} display_channel={false}/>
        </List.ul>
      <% end %>
    """
end
