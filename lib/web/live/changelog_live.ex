defmodule MediaWatchWeb.ChangelogLive do
  # TODO: It's completely overkill and unefficient to use a live-view for
  # this when the page could be generated statically during compilation,
  # but that will do for now.
  use MediaWatchWeb, :live_view
  @changelog_path Application.app_dir(:media_watch, "priv/CHANGELOG-USER.md")

  @impl true
  def mount(_params, _session, socket), do: {:ok, socket}

  @impl true
  def render(assigns),
    do: ~H"""
    <h1>Nouveautés</h1>

    <%= get_changelog() %>
    """

  def get_changelog() do
    with {:ok, content} <- File.read(@changelog_path),
         {:ok, as_html, _} <- Earmark.as_html(content),
         do: as_html |> Phoenix.HTML.raw()
  end
end
