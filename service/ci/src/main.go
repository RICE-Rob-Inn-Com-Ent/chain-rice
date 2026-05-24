// Package main is the Dagger CI module for .rice: the [Rice] type and its methods orchestrate
// audit, forge, prepare, cook, pour, perform, think, serve, and pipeline workflows across the monorepo.
//
// rice CLI ↔ Dagger: repo [README.md](../../README.md) and [CONTRIBUTING.md](../../CONTRIBUTING.md).
//
// The module entrypoint (func main) is generated in dagger.gen.go alongside GraphQL bindings.
// Implementation files: audit.go, cook.go, forge.go, perform.go, pour.go ([Rice] root),
// prepare.go, serve.go, think.go.
//
// Internal packages: internal/dagger, internal/querybuilder.
package main
