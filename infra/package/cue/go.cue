package package

languageGo: {
  manager:      "go"
  manifestFile: "go.mod"
  ecosystem:    "go"
  manifests: [
    "service/auth/go.mod",
    "service/bench/go.mod",
    "service/ci/go.mod",
    "service/database/go.mod",
    "service/database/sqlc.yaml",
    "service/kit/go.mod",
    "service/queue/go.mod",
    "service/token/go.mod",
    "service/web/go.mod",
    "service/.golangci.yml",
    "service/go.work",
  ]

  defaults: {
    goVersion: "1.23"
  }

  sharedRequires: {
    grpc:      "google.golang.org/grpc v1.67.1"
    protobuf:  "google.golang.org/protobuf v1.35.1"
    zap:       "go.uber.org/zap v1.27.0"
    chi:       "github.com/go-chi/chi/v5 v5.1.0"
  }

  modules: {
    auth:     {path: "service/auth/go.mod",     moduleName: "rice/service/auth",       requires: ["grpc", "protobuf", "zap"]}
    bench:    {path: "service/bench/go.mod",    moduleName: "rice/service/bench",      requires: ["grpc", "protobuf", "zap"]}
    ci:       {path: "service/ci/go.mod",       moduleName: "rice/service/ci",         requires: ["grpc", "protobuf", "zap"]}
    database: {path: "service/database/go.mod", moduleName: "rice/service/database",   requires: ["grpc", "protobuf", "zap"]}
    kit:      {path: "service/kit/go.mod",      moduleName: "rice/service/kit",        requires: ["grpc", "protobuf", "zap"]}
    queue:    {path: "service/queue/go.mod",    moduleName: "rice/service/queue",      requires: ["grpc", "protobuf", "zap"]}
    token:    {path: "service/token/go.mod",    moduleName: "rice/service/token",      requires: ["grpc", "protobuf", "zap"]}
    web:      {path: "service/web/go.mod",      moduleName: "rice/service/web",        requires: ["grpc", "protobuf", "zap", "chi"]}
  }

  constraints: {
    requiredSharedDeps: [for _, module in modules for req in module.requires {sharedRequires[req]}]
  }

  render: {
    goMods: [
      {name: "auth",     path: modules.auth.path,     kind: "go-mod", data: {module: modules.auth.moduleName,     go: defaults.goVersion, requires: modules.auth.requires,     requireVersions: sharedRequires}},
      {name: "bench",    path: modules.bench.path,    kind: "go-mod", data: {module: modules.bench.moduleName,    go: defaults.goVersion, requires: modules.bench.requires,    requireVersions: sharedRequires}},
      {name: "ci",       path: modules.ci.path,       kind: "go-mod", data: {module: modules.ci.moduleName,       go: defaults.goVersion, requires: modules.ci.requires,       requireVersions: sharedRequires}},
      {name: "database", path: modules.database.path, kind: "go-mod", data: {module: modules.database.moduleName, go: defaults.goVersion, requires: modules.database.requires, requireVersions: sharedRequires}},
      {name: "kit",      path: modules.kit.path,      kind: "go-mod", data: {module: modules.kit.moduleName,      go: defaults.goVersion, requires: modules.kit.requires,      requireVersions: sharedRequires}},
      {name: "queue",    path: modules.queue.path,    kind: "go-mod", data: {module: modules.queue.moduleName,    go: defaults.goVersion, requires: modules.queue.requires,    requireVersions: sharedRequires}},
      {name: "token",    path: modules.token.path,    kind: "go-mod", data: {module: modules.token.moduleName,    go: defaults.goVersion, requires: modules.token.requires,    requireVersions: sharedRequires}},
      {name: "web",      path: modules.web.path,      kind: "go-mod", data: {module: modules.web.moduleName,      go: defaults.goVersion, requires: modules.web.requires,      requireVersions: sharedRequires}},
    ]
  }

  emitFiles: []
}
