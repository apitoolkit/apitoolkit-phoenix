defmodule ApitoolkitPhoenix.MixProject do
  use Mix.Project

  def project do
    [
      app: :apitoolkit_phoenix,
      version: "0.1.0",
      description: "APIToolkit's Phoenix integration sdks",
      elixir: "~> 1.15",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
      {:jason, "~> 1.2"},
      {:dns_cluster, "~> 0.1.1"},
      {:plug_cowboy, "~> 2.5"},
      {:httpoison, "~> 1.8"},
      {:google_api_pub_sub, "~> 0.36.0"},
      {:goth, "~> 1.0"},
      {:uuid, "~> 1.1"},
      {:phoenix, "~> 1.7.10"}
    ]
  end
end
