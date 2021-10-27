defmodule MediaWatchWeb.ItemDescriptionView do
  use MediaWatchWeb, :view

  def description(%{description: desc}), do: desc
  def description(_), do: "Pas de description disponible"

  def image_url(%{image: %{"url" => url}}) when not is_nil(url), do: url
  def image_url(_), do: nil

  def link(%{link: link}) when not is_nil(link), do: link
  def link(_), do: nil
end
