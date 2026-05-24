# otel-go

This is our OpenTelemetry dependency plumbing repository. There are many like it, but this one is ours.

# why

This package is imported by generated Dagger code, and the Dagger engine itself, and is separated out from `dagger.io/dagger` so that we can tag new versions and ship it independently whenever we need to bump the OpenTelemetry version. Otherwise we have a chicken-egg problem any time an OTel bump involves breaking changes, as the OTel logging SDK tends to have while it's pre-1.0.

## versioning

This repository's semver tags track OpenTelemetry Go SDK's versions. Which also means we can't tag our own versions, but that should be fine most of the time; we'll just pin to an exact commit when needed.
