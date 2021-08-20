import Ecto.Changeset

alias MediaWatch.{Repo, Catalog, Snapshots, Parsing, Analysis, Http}

alias MediaWatch.Catalog.{Show, Item, Source}
alias MediaWatch.Catalog.Source.RssFeed

alias MediaWatch.Snapshots.Snapshot
alias MediaWatch.Snapshots.Snapshot.Xml

alias MediaWatch.Parsing.ParsedSnapshot

alias MediaWatch.Analysis.Facet
alias MediaWatch.Analysis.Facet.{ShowOccurrence, Description}
