defmodule Smith.Core.MixProject do
  use Mix.Project

  def project do
    [
      app: :core,
      version: "0.1.0",
      build_path: "../_build",
      config_path: "../config/config.exs",
      deps_path: "../deps",
      lockfile: "../mix.lock",
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger, :runtime_tools],
      mod: {Smith.Core.Application, []}
    ]
  end

  defp deps do
    [
      {:phoenix,                "~> 1.7"},
      {:phoenix_live_view,      "~> 1.0"},
      {:bandit,                 "~> 1.5"},
      {:phoenix_pubsub,         "~> 2.1"},
      {:phoenix_live_dashboard, "~> 0.8"},
      {:messages,   in_umbrella: true},
      {:guard,      in_umbrella: true},
      {:connection, in_umbrella: true}
    ]
  end
end
