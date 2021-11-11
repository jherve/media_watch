defmodule MediaWatch.MixProject do
  use Mix.Project
  @app_name :media_watch

  def project do
    [
      app: @app_name,
      version: from_file(),
      elixir: "~> 1.7",
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: [:phoenix, :gettext] ++ Mix.compilers(),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
      releases: [
        {@app_name, [steps: [:assemble, &export_sha1/1, &export_docker_image_tag/1, :tar]]}
      ]
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {MediaWatch.Application, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:phoenix, "~> 1.6"},
      {:phoenix_ecto, "~> 4.1"},
      {:ecto_sql, "~> 3.4"},
      {:postgrex, ">= 0.0.0"},
      {:phoenix_live_view, "~> 0.17"},
      {:mint, "~> 1.4"},
      {:floki, ">= 0.30.0"},
      {:phoenix_html, "~> 3.1"},
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      {:phoenix_live_dashboard, "~> 0.6"},
      {:telemetry_metrics, "~> 0.6.1"},
      {:telemetry_poller, "~> 1.0"},
      {:gettext, "~> 0.11"},
      {:jason, "~> 1.0"},
      {:plug_cowboy, "~> 2.0"},
      {:ecto_sqlite3, "~> 0.7.0"},
      {:finch, "~> 0.9"},
      {:elixir_feed_parser, "~> 2.1.0"},
      {:timex, "~> 3.7"},
      {:dialyxir, "~> 1.0", only: [:dev], runtime: false},
      {:credo, "~> 1.5", only: [:dev, :test], runtime: false},
      {:esbuild, "~> 0.2", runtime: Mix.env() == :dev},
      {:crontab, "~> 1.1"},
      {:ex_cldr_dates_times, "~> 2.0"},
      {:quantum, "~> 3.0"},
      {:earmark, "~> 1.4"}
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to install project dependencies and perform other setup tasks, run:
  #
  #     $ mix setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      setup: ["deps.get", "ecto.setup", "cmd npm install --prefix assets"],
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ecto.create --quiet", "ecto.migrate --quiet", "test"],
      "assets.deploy": ["esbuild default --minify", "phx.digest"]
    ]
  end

  defp from_file(file \\ "VERSION") do
    with {:ok, described} <- File.read(file),
         {:ok, version} <- described |> String.trim() |> to_semver_string() do
      version
    end
  end

  defp to_semver_string(described) when is_binary(described) do
    with {:ok, _} <- described |> Version.parse(), do: {:ok, described}
  end

  defp export_sha1(rel) when is_struct(rel, Mix.Release) do
    with {sha1, 0} <- System.cmd("git", ["rev-parse", "HEAD"]),
         :ok <- rel |> write_in_rel_path("git-sha1", sha1),
         do: rel
  end

  defp export_docker_image_tag(rel) when is_struct(rel, Mix.Release) do
    with image_tag when not is_nil(image_tag) <- System.get_env("DOCKER_IMAGE_TAG"),
         :ok <- rel |> write_in_rel_path("docker-image-tag", "#{image_tag}\n") do
      rel
    else
      nil -> rel
    end
  end

  defp write_in_rel_path(%{version_path: path}, file_path, content) do
    path |> Path.join(file_path) |> File.write(content)
  end
end
