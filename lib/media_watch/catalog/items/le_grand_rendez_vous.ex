defmodule MediaWatch.Catalog.Item.LeGrandRendezVous do
  use MediaWatch.Catalog.ItemWorker,
    show: %{
      name: "Le grand rendez-vous",
      url: "https://www.europe1.fr/emissions/Le-grand-rendez-vous",
      airing_schedule: "0 10 * * SUN",
      duration_minutes: 45
    },
    sources: [%{rss_feed: %{url: "https://www.europe1.fr/rss/podcasts/le-grand-rendez-vous.xml"}}],
    channel_names: ["Europe 1"]
end
