# MediaWatch

## Basic commands

Add sources : `mix run priv/repo/seeds.exs`

Make snapshots : `Snapshots.get_jobs() |> Snapshots.run_jobs`

Run snapshots' parsing: `Parsing.get_jobs |> Parsing.run_jobs`

Run analysis of a parsed snapshot : `Parsing.get_all |> List.first |> MediaWatch.Parsing.ParsedSnapshot.slice |> Enum.map(& Repo.insert/1)`

## Connect as admin [reminder for future me]

1. Run a remote Elixir shell on the host machine : `sudo su media_watch -c "/home/media_watch/otp/bin/media_watch remote"`
1. Generate an admin_key `MediaWatch.Auth.generate_admin_key()`
1. Login to the site using URL "/admin?token=xxxx"
