defmodule ExamplesElixirHello.MixProject do
  use Mix.Project

  def project do
    [
      app: :examples_elixir_hello,
      version: "0.1.0",
      elixir: "~> 1.15",
      start_permanent: Mix.env() == :prod,
      deps: [],
      releases: [
        examples_elixir_hello: [
          include_executables_for: [:unix],
          steps: [:assemble],
          applications: [logger: :permanent]
        ]
      ]
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end
end


