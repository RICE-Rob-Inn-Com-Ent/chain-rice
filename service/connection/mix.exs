defmodule Smith.Connection.MixProject do
  use Mix.Project

  def project do
    [
      app: :connection,
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
      extra_applications: [:logger],
      mod: {Smith.Connection.Application, []}
    ]
  end

  defp deps do
    [
      {:libcluster, "~> 3.4"},
      {:horde,      "~> 0.9"},
      {:telemetry,  "~> 1.3"}
    ]
  end
end
