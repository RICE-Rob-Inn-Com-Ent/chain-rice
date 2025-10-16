defmodule ConnectionBeam.MixProject do
  use Mix.Project

  def project do
    [
      app: :connection_beam,
      version: "0.1.0",
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

  # Dependencies
  defp deps do
    [
      {:grpc, "~> 0.10"},
      {:httpoison, "~> 2.2"},
      {:jason, "~> 1.4"},
      {:phoenix, "~> 1.8"},
      {:msgpax, "~> 2.4"},
      {:protobuf, "~> 0.15"}
    ]
  end
end
