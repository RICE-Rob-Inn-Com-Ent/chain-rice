# Elixir formatter | Rice monorepo
# mix format (uses this when run from project with mix.exs)
# https://hexdocs.pm/mix/Mix.Tasks.Format.html

[
  import_deps: [:phoenix, :ecto_sql, :plug_cowboy],
  inputs: ["*.{ex,exs}", "{config,lib,test}/**/*.{ex,exs}"],
  subdirectories: ["config", "lib", "test"],
  line_length: 120
]
