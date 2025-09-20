# ChainRice Docker Bake Configuration
# This file defines all Docker images for the ChainRice project

group "default" {
  targets = [
    "chainrice-go",
    "chainrice-dotnet-bridge",
    "chainrice-beam-bridge", 
    "chainrice-python-bridge",
    "chainrice-jvm-bridge",
    "chainrice-php-bridge",
    "chainrice-auto",
    "chainrice-contracts",
    "chainrice-data",
    "chainrice-dev",
    "chainrice-misc"
  ]
}

# Backend Services
target "chainrice-go" {
  dockerfile = "containers/Dockerfile.GO.main"
  context = "."
  tags = ["chainrice/go:latest", "chainrice/go:dev"]
  platforms = ["linux/amd64", "linux/arm64"]
}

target "chainrice-dotnet-bridge" {
  dockerfile = "containers/Dockerfile.NET.bridge"
  context = "."
  tags = ["chainrice/dotnet-bridge:latest", "chainrice/dotnet-bridge:dev"]
  platforms = ["linux/amd64", "linux/arm64"]
}

target "chainrice-beam-bridge" {
  dockerfile = "containers/Dockerfile.BEAM.bridge"
  context = "."
  tags = ["chainrice/beam-bridge:latest", "chainrice/beam-bridge:dev"]
  platforms = ["linux/amd64", "linux/arm64"]
}

target "chainrice-python-bridge" {
  dockerfile = "containers/Dockerfile.CPython.bridge"
  context = "."
  tags = ["chainrice/python-bridge:latest", "chainrice/python-bridge:dev"]
  platforms = ["linux/amd64", "linux/arm64"]
}

target "chainrice-jvm-bridge" {
  dockerfile = "containers/Dockerfile.JVM.bridge"
  context = "."
  tags = ["chainrice/jvm-bridge:latest", "chainrice/jvm-bridge:dev"]
  platforms = ["linux/amd64", "linux/arm64"]
}

target "chainrice-php-bridge" {
  dockerfile = "containers/Dockerfile.PHP.bridge"
  context = "."
  tags = ["chainrice/php-bridge:latest", "chainrice/php-bridge:dev"]
  platforms = ["linux/amd64", "linux/arm64"]
}

# Tools Services
target "chainrice-auto" {
  dockerfile = "containers/Dockerfile.AUTO.tool"
  context = "."
  tags = ["chainrice/auto:latest", "chainrice/auto:dev"]
  platforms = ["linux/amd64", "linux/arm64"]
}

target "chainrice-contracts" {
  dockerfile = "containers/Dockerfile.CONTRACTS.tool"
  context = "."
  tags = ["chainrice/contracts:latest", "chainrice/contracts:dev"]
  platforms = ["linux/amd64", "linux/arm64"]
}

target "chainrice-data" {
  dockerfile = "containers/Dockerfile.DATA.tool"
  context = "."
  tags = ["chainrice/data:latest", "chainrice/data:dev"]
  platforms = ["linux/amd64", "linux/arm64"]
}

target "chainrice-dev" {
  dockerfile = "containers/Dockerfile.DEV.tool"
  context = "."
  tags = ["chainrice/dev:latest", "chainrice/dev:dev"]
  platforms = ["linux/amd64", "linux/arm64"]
}

target "chainrice-misc" {
  dockerfile = "containers/Dockerfile.MISC.tool"
  context = "."
  tags = ["chainrice/misc:latest", "chainrice/misc:dev"]
  platforms = ["linux/amd64", "linux/arm64"]
}

# Development group - all services for local development
group "dev" {
  targets = [
    "chainrice-go",
    "chainrice-dotnet-bridge",
    "chainrice-beam-bridge",
    "chainrice-python-bridge", 
    "chainrice-jvm-bridge",
    "chainrice-php-bridge",
    "chainrice-auto",
    "chainrice-contracts",
    "chainrice-data",
    "chainrice-dev",
    "chainrice-misc"
  ]
}

# Production group - optimized builds
group "prod" {
  targets = [
    "chainrice-go",
    "chainrice-dotnet-bridge",
    "chainrice-beam-bridge",
    "chainrice-python-bridge",
    "chainrice-jvm-bridge", 
    "chainrice-php-bridge"
  ]
}

# Tools group - only tools services
group "tools" {
  targets = [
    "chainrice-auto",
    "chainrice-contracts", 
    "chainrice-data",
    "chainrice-dev",
    "chainrice-misc"
  ]
}

# Bridges group - only bridge services
group "bridges" {
  targets = [
    "chainrice-dotnet-bridge",
    "chainrice-beam-bridge",
    "chainrice-python-bridge",
    "chainrice-jvm-bridge",
    "chainrice-php-bridge"
  ]
}
