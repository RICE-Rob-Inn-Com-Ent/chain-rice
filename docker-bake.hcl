group "default" {
  targets = ["blockchain", "backend", "web-frontend"]
}

target "blockchain" {
  context = "."
  dockerfile = "Dockerfile.blockchain"
  args = {
    BUILD_ENV = "development"
    BUILD_NUMBER = "1"
    BUILD_DATE = "2025-01-01"
    BUILD_VERSION = "1.0.0"
    BUILD_COMMIT = "1234567890"
  }
}

target "backend" {
  context = "./meowtopia/backend"
  dockerfile = "Dockerfile.backend"
  args = {
    BUILD_ENV = "development"
    BUILD_NUMBER = "1"
    BUILD_DATE = "2025-01-01"
    BUILD_VERSION = "1.0.0"
    BUILD_COMMIT = "1234567890"
  }
}

target "web-frontend" {
  context = "./meowtopia/frontend/web"
  dockerfile = "Dockerfile.web"
  args = {
    BUILD_ENV = "development"
    BUILD_NUMBER = "1"
    BUILD_DATE = "2025-01-01"
    BUILD_VERSION = "1.0.0"
    BUILD_COMMIT = "1234567890"
  }
}
