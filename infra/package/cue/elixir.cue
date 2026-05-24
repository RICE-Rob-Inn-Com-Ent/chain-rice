package package

languageElixir: {
  manager:      "mix"
  manifestFile: "mix.exs"
  ecosystem:    "elixir"
  manifests: [
    "service/config/config.exs",
    "service/connection/mix.exs",
    "service/core/mix.exs",
    "service/guard/mix.exs",
    "service/messages/mix.exs",
    "service/mix.exs",
    "service/pipeline/mix.exs",
    "service/.credo.exs",
    "service/.formatter.exs",
  ]

  defaults: {
    version:  "0.1.0"
    elixir:   "~> 1.17"
    otpAppNs: "rice"
  }

  sharedDeps: {
    jason:     "~> 1.4"
    ecto:      "~> 3.12"
    telemetry: "~> 1.2"
    phoenixPubSub: "~> 2.1"
  }

  apps: {
    root:       {path: "service/mix.exs",            appName: "rice_service",             moduleName: "Rice.Service",            deps: ["jason", "telemetry"]}
    connection: {path: "service/connection/mix.exs", appName: "rice_service_connection",  moduleName: "Rice.Service.Connection", deps: ["jason", "telemetry", "phoenixPubSub"]}
    core:       {path: "service/core/mix.exs",       appName: "rice_service_core",        moduleName: "Rice.Service.Core",       deps: ["jason", "ecto", "telemetry"]}
    guard:      {path: "service/guard/mix.exs",      appName: "rice_service_guard",       moduleName: "Rice.Service.Guard",      deps: ["jason", "telemetry"]}
    messages:   {path: "service/messages/mix.exs",   appName: "rice_service_messages",    moduleName: "Rice.Service.Messages",   deps: ["jason", "phoenixPubSub", "telemetry"]}
    pipeline:   {path: "service/pipeline/mix.exs",   appName: "rice_service_pipeline",    moduleName: "Rice.Service.Pipeline",   deps: ["jason", "ecto", "telemetry"]}
  }

  constraints: {
    requiredSharedDeps: [for _, app in apps for dep in app.deps {sharedDeps[dep]}]
  }

  render: {
    mixProjects: [
      {name: "root",       path: apps.root.path,       kind: "mix-project", data: {app: apps.root.appName,       module: apps.root.moduleName,       version: defaults.version, elixir: defaults.elixir, deps: apps.root.deps,       depVersions: sharedDeps}},
      {name: "connection", path: apps.connection.path, kind: "mix-project", data: {app: apps.connection.appName, module: apps.connection.moduleName, version: defaults.version, elixir: defaults.elixir, deps: apps.connection.deps, depVersions: sharedDeps}},
      {name: "core",       path: apps.core.path,       kind: "mix-project", data: {app: apps.core.appName,       module: apps.core.moduleName,       version: defaults.version, elixir: defaults.elixir, deps: apps.core.deps,       depVersions: sharedDeps}},
      {name: "guard",      path: apps.guard.path,      kind: "mix-project", data: {app: apps.guard.appName,      module: apps.guard.moduleName,      version: defaults.version, elixir: defaults.elixir, deps: apps.guard.deps,      depVersions: sharedDeps}},
      {name: "messages",   path: apps.messages.path,   kind: "mix-project", data: {app: apps.messages.appName,   module: apps.messages.moduleName,   version: defaults.version, elixir: defaults.elixir, deps: apps.messages.deps,   depVersions: sharedDeps}},
      {name: "pipeline",   path: apps.pipeline.path,   kind: "mix-project", data: {app: apps.pipeline.appName,   module: apps.pipeline.moduleName,   version: defaults.version, elixir: defaults.elixir, deps: apps.pipeline.deps,   depVersions: sharedDeps}},
    ]
  }

  emitFiles: []
}
