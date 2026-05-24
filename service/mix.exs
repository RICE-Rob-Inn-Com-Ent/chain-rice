defmodule Smith.MixProject do
  use Mix.Project

  def project do
    [
      apps_path: ".",
      apps: [:messages, :guard, :core, :pipeline, :cluster, :connection],
      version: "0.1.0",
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      releases: releases(),
      deps: deps()
    ]
  end

  defp releases do
    [
      core: [
        applications: [
          core: :permanent,
          messages: :permanent,
          guard: :permanent,
          connection: :permanent,
          pipeline: :permanent,
          cluster: :permanent
        ]
      ]
    ]
  end

  defp deps do
    [
      {:ex_doc,      "~> 0.34", only: :dev,         runtime: false},
      {:credo,       "~> 1.7",  only: [:dev, :test], runtime: false},
      {:dialyxir,    "~> 1.4",  only: [:dev, :test], runtime: false},
      {:excoveralls, "~> 0.18", only: :test},
      {:mox,         "~> 1.2",  only: :test}
    ]
  end
end
