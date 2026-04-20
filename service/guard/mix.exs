defmodule Smith.Guard.MixProject do
  use Mix.Project

  def project do
    [
      app: :guard,
      version: "0.1.0",
      build_path: "../_build",
      config_path: "../config/config.exs",
      deps_path: "../deps",
      lockfile: "../mix.lock",
      elixir: "~> 1.18",
      start_permanent: true,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger, :runtime_tools],
      mod: {Smith.Guard.Application, []}
    ]
  end

  defp deps do
    [
      {:opentelemetry,          "~> 1.5"},
      {:opentelemetry_api,      "~> 1.4"},
      {:opentelemetry_exporter, "~> 1.8"},
      {:opentelemetry_phoenix,  "~> 2.0"},
      {:telemetry,              "~> 1.3"},
      {:telemetry_metrics,      "~> 1.0"},
      {:telemetry_poller,       "~> 1.1"}
    ]
  end
end
