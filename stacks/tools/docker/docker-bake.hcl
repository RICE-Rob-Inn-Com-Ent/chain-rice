group "default" {
  targets = ["app"]
}

group "languages" {
  targets = [
    "python", "go", "rust", "java", "csharp", "kotlin", "php", "dart",
    "clojure", "cpp", "erlang", "elixir", "fsharp", "groovy", "haskell",
    "julia", "octave", "ocaml", "scala", "swift", "solidity", "sql", "proto"
  ]
}

target "app" {
  context = "."
  dockerfile = "Dockerfile"
  tags = [
    "examples-docker-hello:latest",
  ]
  args = {
    PORT = "8080"
    APP_NAME = "examples-docker-hello-bake"
  }
}

target "dev" {
  inherits = ["app"]
  dockerfile = "Dockerfile.dev"
  tags = [
    "examples-docker-hello:dev",
  ]
  args = {
    APP_NAME = "examples-docker-hello-bake-dev"
  }
}

# Language containers
target "python" {
  context = "./containers"
  dockerfile = "Dockerfile.py.cont"
  tags = ["rice-dev/python:latest"]
}

target "go" {
  context = "./containers"
  dockerfile = "Dockerfile.go.cont"
  tags = ["rice-dev/go:latest"]
}

target "rust" {
  context = "./containers"
  dockerfile = "Dockerfile.rs.cont"
  tags = ["rice-dev/rust:latest"]
}

target "java" {
  context = "./containers"
  dockerfile = "Dockerfile.java.cont"
  tags = ["rice-dev/java:latest"]
}

target "csharp" {
  context = "./containers"
  dockerfile = "Dockerfile.cs.cont"
  tags = ["rice-dev/csharp:latest"]
}

target "kotlin" {
  context = "./containers"
  dockerfile = "Dockerfile.kt.cont"
  tags = ["rice-dev/kotlin:latest"]
}

target "php" {
  context = "./containers"
  dockerfile = "Dockerfile.php.cont"
  tags = ["rice-dev/php:latest"]
}

target "dart" {
  context = "./containers"
  dockerfile = "Dockerfile.dart.cont"
  tags = ["rice-dev/dart:latest"]
}

target "clojure" {
  context = "./containers"
  dockerfile = "Dockerfile.clj.cont"
  tags = ["rice-dev/clojure:latest"]
}

target "cpp" {
  context = "./containers"
  dockerfile = "Dockerfile.cpp.cont"
  tags = ["rice-dev/cpp:latest"]
}

target "erlang" {
  context = "./containers"
  dockerfile = "Dockerfile.erl.cont"
  tags = ["rice-dev/erlang:latest"]
}

target "elixir" {
  context = "./containers"
  dockerfile = "Dockerfile.ex.cont"
  tags = ["rice-dev/elixir:latest"]
}

target "fsharp" {
  context = "./containers"
  dockerfile = "Dockerfile.fs.cont"
  tags = ["rice-dev/fsharp:latest"]
}

target "groovy" {
  context = "./containers"
  dockerfile = "Dockerfile.groovy.cont"
  tags = ["rice-dev/groovy:latest"]
}

target "haskell" {
  context = "./containers"
  dockerfile = "Dockerfile.hs.cont"
  tags = ["rice-dev/haskell:latest"]
}

target "julia" {
  context = "./containers"
  dockerfile = "Dockerfile.jl.cont"
  tags = ["rice-dev/julia:latest"]
}

target "octave" {
  context = "./containers"
  dockerfile = "Dockerfile.m.cont"
  tags = ["rice-dev/octave:latest"]
}

target "ocaml" {
  context = "./containers"
  dockerfile = "Dockerfile.ml.cont"
  tags = ["rice-dev/ocaml:latest"]
}

target "scala" {
  context = "./containers"
  dockerfile = "Dockerfile.scala.cont"
  tags = ["rice-dev/scala:latest"]
}

target "swift" {
  context = "./containers"
  dockerfile = "Dockerfile.swift.cont"
  tags = ["rice-dev/swift:latest"]
}

target "solidity" {
  context = "./containers"
  dockerfile = "Dockerfile.sol.cont"
  tags = ["rice-dev/solidity:latest"]
}

target "sql" {
  context = "./containers"
  dockerfile = "Dockerfile.sql.cont"
  tags = ["rice-dev/sql:latest"]
}

target "proto" {
  context = "./containers"
  dockerfile = "Dockerfile.proto.cont"
  tags = ["rice-dev/proto:latest"]
}

