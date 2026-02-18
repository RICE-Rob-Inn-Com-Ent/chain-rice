defmodule ImmortalSystem.MixProject do
  use Mix.Project

  def project do
    [
      app: :immortal_system,
      version: "0.1.0",
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      # Mix automatycznie skompiluje pliki Erlanga z folderu src/
      erlc_paths: ["src"],
      # Wsparcie dla natywnych bibliotek Rusta (Rustler)
      compilers: Mix.compilers()
    ]
  end

  def application do
    [
      extra_applications: [:logger, :runtime_tools],
      # Supervisor to serce nieśmiertelności systemu
      mod: {ImmortalSystem.Application, []}
    ]
  end

  defp deps do
    [
      # --- LIVE COMMUNICATION & NETWORKING ---
      {:phoenix_gen_socket_client, "~> 4.0"}, # Ultra-wydajne sockety
      {:thousand_island, "~> 1.3"},          # Najnowocześniejszy serwer TCP/Webstack w Elixirze (szybszy niż Cowboy)
      {:bandit, "~> 1.6"},                   # Serwer HTTP oparty na Thousand Island

      # --- PERFORMANCE & COMPUTATION ---
      {:rustler, "~> 0.35"},                 # Integracja z Rustem (NIFs) dla max wydajności
      {:jason, "~> 1.4"},                    # Najszybszy parser JSON
      {:telemetry, "~> 1.3"},                # Metryki w czasie rzeczywistym bez spadku wydajności

      # --- DURABILITY & FAULT TOLERANCE ---
      {:horde, "~> 0.9"},                    # Rozproszony Supervisor (system żyje nawet jak padnie węzeł)
      {:nebulex, "~> 2.6"},                  # Ultra-szybki system cachowania (local & distributed)

      # --- UTILS ---
      {:libcluster, "~> 3.5"},               # Automatyczne klastrowanie węzłów w chmurze/K8s
      {:credo, "~> 1.7", runtime: false, only: [:dev, :test]},
    {:dialyxir, "~> 1.4", runtime: false, only: [:dev, :test]}
    ]
  end
end
