group "default" {
  targets = ["app"]
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


