defmodule MediaWatchWeb.ItemIndexLive do
  use MediaWatchWeb, :live_view
  alias MediaWatch.Analysis
  alias MediaWatchWeb.Component.List
  alias MediaWatchWeb.ItemLiveComponent
  alias MediaWatchWeb.ItemView

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket |> assign(items: Analysis.get_all_analyzed_items())}
  end

  @impl true
  def render(assigns),
    do: ~H"""
      <h1>Liste des émissions</h1>

      <List.ul let={item} list={@items} class="item card" id="item-index-list">
        <a href={ItemView.detail_link(item.id)}>
          <.live_component module={ItemLiveComponent} id={item.id} item={item}/>
        </a>
      </List.ul>
    """
end
