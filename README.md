# MediaWatch

## Basic commands

Add sources : `mix run priv/repo/seeds.exs`

Make snapshots : `Snapshots.get_jobs() |> Snapshots.run_jobs`

Run snapshots' parsing: `Parsing.get_jobs |> Parsing.run_jobs`

Run analysis of a parsed snapshot : `Parsing.get_all |> List.first |> MediaWatch.Parsing.ParsedSnapshot.slice |> Enum.map(& Repo.insert/1)`
