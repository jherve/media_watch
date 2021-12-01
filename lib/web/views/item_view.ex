defmodule MediaWatchWeb.ItemView do
  use MediaWatchWeb, :view
  alias MediaWatch.Schedule

  def title(item), do: item.show.name

  def channels(item), do: item.channels |> Enum.map(& &1.name) |> Enum.join(", ")

  def schedule(item), do: item.show.airing_schedule |> Schedule.to_string()

  def detail_link(item_id),
    do: MediaWatchWeb.Router.Helpers.item_path(MediaWatchWeb.Endpoint, :detail, item_id)
end
