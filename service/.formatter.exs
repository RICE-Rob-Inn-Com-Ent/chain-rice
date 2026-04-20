# Elixir formatter | Rice monorepo
# mix format (uses this when run from project with mix.exs)
# https://hexdocs.pm/mix/Mix.Tasks.Format.html

[
  import_deps: [:phoenix, :ecto_sql, :plug_cowboy],
  inputs: ["*.{ex,exs}", "{config,core,pipeline,cluster,guard,connection,test}/**/*.{ex,exs}"],
  subdirectories: ["config", "core", "pipeline", "cluster", "guard", "connection", "test"],
  line_length: 120
]
