defmodule Streamshore.MixProject do
  use Mix.Project

  def project do
    [
      app: :streamshore,
      version: "0.1.0",
      elixir: "~> 1.5",
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: Mix.compilers(),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps()
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {Streamshore.Application, []},
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
      {:phoenix, "~> 1.7"},
      {:phoenix_pubsub, "~> 2.1"},
      {:phoenix_ecto, "~> 4.6"},
      {:ecto_sql, "~> 3.12"},
      {:myxql, "~> 0.7.1"},
      {:phoenix_html, "~> 4.2"},
      {:phoenix_live_reload, "~> 1.5", only: :dev},
      {:jason, "~> 1.4"},
      {:plug_cowboy, "~> 2.7"},
      {:dictionary, github: "nextinfinity/dictionary"},
      {:plug, "~> 1.16"},
      {:corsica, "~> 2.1"},
      {:joken, "~> 2.6"},
      {:comeonin, "~> 5.5"},
      {:pbkdf2_elixir, "~> 2.3"},
      {:httpoison, "~> 2.2"},
      {:poison, "~> 6.0"},
      {:timex, "~> 3.7"},
      {:uuid, "~> 1.1"},
      {:guardian, "~> 2.3"},
      {:sendgrid, "~> 2.0"}
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
      test: ["ecto.create --quiet", "ecto.migrate", "test"]
    ]
  end
end
