defmodule ChainRice.Bridge.MixProject do
  use Mix.Project

  def project do
    [
      app: :chainrice_bridge,
      version: "1.0.0",
      elixir: "~> 1.16",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: "Bridge library for connecting Elixir/Erlang applications to ChainRice Go services",
      package: package()
    ]
  end

  def application do
    [
      extra_applications: [:logger, :inets, :ssl],
      mod: {ChainRice.Bridge.Application, []}
    ]
  end

  defp deps do
    [
      # HTTP client
      {:req, "~> 0.4"},
      {:finch, "~> 0.16"},
      
      # JSON handling
      {:jason, "~> 1.4"},
      {:poison, "~> 5.0"},
      
      # gRPC
      {:grpc, "~> 0.5"},
      {:protobuf, "~> 0.12"},
      
      # Configuration
      {:confex, "~> 3.5"},
      
      # Logging
      {:logger_json, "~> 5.1"},
      
      # Testing
      {:ex_doc, "~> 0.31", only: :dev, runtime: false},
      {:ex_unit, "~> 1.0", only: :test},
      {:mox, "~> 1.0", only: :test}
    ]
  end

  defp package do
    [
      maintainers: ["ChainRice Team"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/chainrice/bridge-beam"}
    ]
  end
end
