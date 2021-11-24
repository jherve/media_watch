defmodule MediaWatchWeb.ItemIndexLive do
  use MediaWatchWeb, :live_view
  alias MediaWatch.Analysis
  alias MediaWatchWeb.Component.List
  alias MediaWatchWeb.ItemLiveComponent
  alias MediaWatchWeb.ItemView

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(
       items_by_channel:
         Analysis.get_all_analyzed_items()
         |> Enum.group_by(& &1.channels)
         |> Enum.flat_map(fn {chan_list, item} -> chan_list |> Enum.map(&{&1, item}) end)
     )}
  end

  @impl true
  def render(assigns),
    do: ~H"""
      <h1>Liste des émissions</h1>

      <%= for {channel, item_list} <- @items_by_channel do %>
        <h2><%= channel.name %></h2>

        <List.ul let={item} list={item_list} ul_class="item card item-index-list" li_class="item card">
          <a href={ItemView.detail_link(item.id)}>
            <.live_component module={ItemLiveComponent} id={item.id} item={item} display_channel={false}/>
          </a>
        </List.ul>
      <% end %>
    """
end
