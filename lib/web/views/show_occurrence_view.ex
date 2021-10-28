defmodule MediaWatchWeb.ShowOccurrenceView do
  use MediaWatchWeb, :view

  def link_by_date(date = %Date{}),
    do:
      MediaWatchWeb.Router.Helpers.show_occurrence_index_path(MediaWatchWeb.Endpoint, :index,
        date: date |> Timex.format!("{YYYY}-{0M}-{0D}")
      )
end
