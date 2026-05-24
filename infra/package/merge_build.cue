package package

// Buck2 buildPlan from infra/build — single package for `cue export` (no multi-package CLI merge).
import b "github.com/rice-rob-inn-com-ent/rice/infra/build/cue:build"

buildPlan: b.buildPlan
