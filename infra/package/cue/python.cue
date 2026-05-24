package package

languagePython: {
  manager:      "uv/pip"
  manifestFile: "pyproject.toml"
  ecosystem:    "python"
  manifests: [
    "function/agent/pyproject.toml",
    "function/bench/pyproject.toml",
    "function/helper/pyproject.toml",
    "function/job/pyproject.toml",
    "function/pyproject.toml",
    "function/simulation/pyproject.toml",
    "function/vector/pyproject.toml",
  ]

  defaults: {
    version:        "0.1.0"
    requiresPython: ">=3.12"
    buildBackend:   "hatchling.build"
  }

  sharedDependencies: {
    pydantic: ">=2.8,<3.0"
    httpx:    ">=0.27,<0.28"
    numpy:    ">=2.0,<3.0"
    typer:    ">=0.12,<1.0"
  }

  projects: {
    root: {
      path: "function/pyproject.toml"
      project: {
        name:           "rice-function"
        version:        defaults.version
        requiresPython: defaults.requiresPython
        dependencies: [
          "pydantic",
          "httpx",
        ]
      }
    }
    agent: {
      path: "function/agent/pyproject.toml"
      project: {
        name:           "rice-function-agent"
        version:        defaults.version
        requiresPython: defaults.requiresPython
        dependencies: [
          "pydantic",
          "httpx",
          "typer",
        ]
      }
    }
    bench: {
      path: "function/bench/pyproject.toml"
      project: {
        name:           "rice-function-bench"
        version:        defaults.version
        requiresPython: defaults.requiresPython
        dependencies: [
          "numpy",
          "typer",
        ]
      }
    }
    helper: {
      path: "function/helper/pyproject.toml"
      project: {
        name:           "rice-function-helper"
        version:        defaults.version
        requiresPython: defaults.requiresPython
        dependencies: [
          "pydantic",
        ]
      }
    }
    job: {
      path: "function/job/pyproject.toml"
      project: {
        name:           "rice-function-job"
        version:        defaults.version
        requiresPython: defaults.requiresPython
        dependencies: [
          "pydantic",
          "httpx",
        ]
      }
    }
    simulation: {
      path: "function/simulation/pyproject.toml"
      project: {
        name:           "rice-function-simulation"
        version:        defaults.version
        requiresPython: defaults.requiresPython
        dependencies: [
          "numpy",
          "pydantic",
        ]
      }
    }
    vector: {
      path: "function/vector/pyproject.toml"
      project: {
        name:           "rice-function-vector"
        version:        defaults.version
        requiresPython: defaults.requiresPython
        dependencies: [
          "numpy",
          "httpx",
        ]
      }
    }
  }

  constraints: {
    // every dependency reference must be declared in sharedDependencies
    requiredSharedDeps: [for _, prj in projects for dep in prj.project.dependencies {sharedDependencies[dep]}]
  }

  render: {
    pyprojectTomls: [
      {name: "root",       path: projects.root.path,       kind: "pyproject", data: {"build-system": {requires: ["hatchling"], "build-backend": defaults.buildBackend}, project: projects.root.project,       dependencyVersions: sharedDependencies}},
      {name: "agent",      path: projects.agent.path,      kind: "pyproject", data: {"build-system": {requires: ["hatchling"], "build-backend": defaults.buildBackend}, project: projects.agent.project,      dependencyVersions: sharedDependencies}},
      {name: "bench",      path: projects.bench.path,      kind: "pyproject", data: {"build-system": {requires: ["hatchling"], "build-backend": defaults.buildBackend}, project: projects.bench.project,      dependencyVersions: sharedDependencies}},
      {name: "helper",     path: projects.helper.path,     kind: "pyproject", data: {"build-system": {requires: ["hatchling"], "build-backend": defaults.buildBackend}, project: projects.helper.project,     dependencyVersions: sharedDependencies}},
      {name: "job",        path: projects.job.path,        kind: "pyproject", data: {"build-system": {requires: ["hatchling"], "build-backend": defaults.buildBackend}, project: projects.job.project,        dependencyVersions: sharedDependencies}},
      {name: "simulation", path: projects.simulation.path, kind: "pyproject", data: {"build-system": {requires: ["hatchling"], "build-backend": defaults.buildBackend}, project: projects.simulation.project, dependencyVersions: sharedDependencies}},
      {name: "vector",     path: projects.vector.path,     kind: "pyproject", data: {"build-system": {requires: ["hatchling"], "build-backend": defaults.buildBackend}, project: projects.vector.project,     dependencyVersions: sharedDependencies}},
    ]
  }

  // pyproject bodies: emit via future serializer; keep empty until TOML writer lands.
  emitFiles: []
}
