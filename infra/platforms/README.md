# Execution platforms (Buck2)

The monorepo uses the **bundled Buck2 prelude** for execution and target platforms:

- `execution_platforms = prelude//platforms:default` (see root `.buckconfig`).

Custom `root//infra/platforms:default` targets are not required for the CLERK shim workflow. Add a `BUILD` file here only if you introduce a dedicated execution platform (e.g. remote execution or cross-compilation).
