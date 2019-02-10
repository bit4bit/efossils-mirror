defmodule Efossils.Mixfile do
  use Mix.Project

  def project do
    [
      app: :efossils,
      version: "0.0.1",
      elixir: "~> 1.4",
      elixirc_paths: elixirc_paths(Mix.env),
      compilers: [:phoenix, :gettext] ++ Mix.compilers,
      start_permanent: Mix.env == :prod,
      aliases: aliases(),
      deps: deps()
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {Efossils.Application, []},
      extra_applications: [:logger, :runtime_tools, :swoosh, :gen_smtp, :httpotion, :porcelain,
                           :scrivener, :scrivener_ecto,:scrivener_html]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_),     do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:phoenix, "~> 1.4.0"},
      {:phoenix_pubsub, "~> 1.1"},
      {:phoenix_ecto, "~> 4.0"},
      {:ecto_sql, "~> 3.0"},
      {:postgrex, ">= 0.0.0"},
      {:phoenix_html, "~> 2.11"},
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      {:gettext, "~> 0.11"},
      {:plug_cowboy, "~> 2.0"},
      {:scrivener, "~> 2.0"},
      {:scrivener_ecto, "~> 2.0"},
      {:scrivener_html, "~> 1.8"},
      {:sizeable, "~> 1.0"},
      {:credo, "~> 0.9.1", only: [:dev, :test], runtime: false},
      {:porcelain, "~> 2.0"},
      {:httpotion, "~> 3.1.0"},
      {:distillery, "~> 1.5", runtime: false},
      {:gen_smtp, "~> 0.12.0"},
      {:jason, "~> 1.0"},
      {:ecto, "~> 3.0"},
      {:poison, "~> 3.1"},
      {:swoosh, "~> 0.21"},
      {:pow, "~> 1.0.1"},
      {:comeonin, "~> 3.0"}
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to create, migrate and run the seeds file at once:
  #
  #     $ mix ecto.setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      "test": ["ecto.create --quiet", "ecto.migrate", "test"]
    ]
  end
end
