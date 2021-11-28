defmodule MediaWatchWeb.PageLive do
  use MediaWatchWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket |> assign(css_page_id: "index")}
  end
end
