defmodule Smith.Pipeline.MixProject do
  use Mix.Project

  def project do
    [
      app: :pipeline,
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
      mod: {Smith.Pipeline.Application, []}
    ]
  end

  defp deps do
    [
      {:broadway,                          "~> 1.1"},
      {:gnat,                              "~> 1.9"},
      {:membrane_core,                     "~> 1.2"},
      {:membrane_file_plugin,              "~> 0.17"},
      {:membrane_audio_mix_plugin,         "~> 0.16"},
      {:membrane_ffmpeg_swresample_plugin, "~> 0.20"},
      {:connection, in_umbrella: true}
    ]
  end
end
