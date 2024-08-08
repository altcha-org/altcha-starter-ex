defmodule AltchaDemoServer.MixProject do
  use Mix.Project

  def project do
    [
      app: :altcha_demo_server,
      version: "0.1.0",
      elixir: "~> 1.17",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {AltchaDemoServer.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
      {:plug_cowboy, "~> 2.0"},
      {:cors_plug, "~> 3.0"},
      {:jason, "~> 1.0"},
      {:dotenv, "~> 3.0"},
      {:altcha, "~> 0.2"}
    ]
  end
end
