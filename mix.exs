defmodule SimpleAgent.MixProject do
  use Mix.Project

  def project do
    [
      app: :simple_agent,
      description: "A simple coding agent implementation in Elixir",
      version: "0.1.0",
      elixir: "~> 1.15",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      escript: [main_module: SimpleAgent.CLI]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [extra_applications: [:logger], mod: {SimpleAgent.Application, []}]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:anthropix, "~> 0.6.1"},
      {:jason, "~> 1.4"},
      {:hermes_mcp, "~> 0.3"}
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
    ]
  end
end
