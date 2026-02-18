defmodule Rice.Elixir.MixProject do
  use Mix.Project

  @version "1.0.0"
  @description "Rice Framework - Elixir Layer: BEAM Supervisor & Resilience"

  def project do
    [
      app: :rice_elixir,
      version: @version,
      elixir: "~> 1.18",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: @description,
      package: [
        maintainers: ["Rice Framework Team"],
        licenses: ["MIT"],
        links: %{"GitHub" => "https://github.com/RICE-Rob-Inn-Com-Ent/rice-mono"}
      ]
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {Rice.Elixir.Application, []}
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      # Phoenix for web framework
      {:phoenix, "~> 1.7"},
      {:phoenix_live_view, "~> 0.20"},

      # Database
      {:ecto_sql, "~> 3.11"},
      {:postgrex, ">= 0.0.0"},

      # OTP & Supervision
      {:telemetry, "~> 1.2"},

      # Development
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false}
    ]
  end
end
