defmodule MediaWatchWeb.PersonView do
  use MediaWatchWeb, :view

  def link_occurrences(person_id),
    do:
      MediaWatchWeb.Router.Helpers.show_occurrence_index_path(MediaWatchWeb.Endpoint, :index,
        person_id: person_id
      )
end
