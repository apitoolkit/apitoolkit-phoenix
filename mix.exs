defmodule ApitoolkitPhoenix.MixProject do
  use Mix.Project

  @source_url "https://github.com/apitoolkit/apitoolkit-phoenix"
  @version "0.1.1"

  def project do
    [
      app: :apitoolkit_phoenix,
      version: @version,
      description: "APIToolkit's Phoenix integration sdks",
      elixir: "~> 1.15",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      package: package(),
      docs: docs()
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

  defp package() do
    [
      maintainers: ["Yussif Mohammed"],
      licenses: ["MIT"],
      links: %{"GitHub" => @source_url}
    ]
  end

  defp docs() do
    [
      main: "readme",
      name: "apitoolkit_phoenix",
      source_ref: "v#{@version}",
      canonical: "http://hexdocs.pm/apitoolkit_phoenix",
      source_url: @source_url,
      extras: ["README.md", "LICENSE"]
    ]
  end
end
