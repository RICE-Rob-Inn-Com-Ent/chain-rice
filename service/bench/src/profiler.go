package bench

// TODO:
// [ ] implement Pyroscope continuous profiling:
//     StartProfiler(appName string) error
//     reads PYROSCOPE_URL from env
//     profiles: cpu, mem, goroutines, mutex, block
//     tags: role=smith, service={name}, env={RICE_ENV}
// [ ] implement profiling modes:
//     RICE_PROFILER_CPU=true — CPU profiling
//     RICE_PROFILER_MEM=true — heap profiling
//     RICE_PROFILER_GOROUTINE=true — goroutine profiling
// [ ] implement on-demand profiling:
//     /debug/pprof endpoint — enabled when RICE_PPROF=true
//     protected by RICE_PPROF_TOKEN — never open in prod

import (
	"context"

	"github.com/grafana/pyroscope-go"
)

// StartPyroscope begins continuous CPU/heap profiling and push to a Pyroscope-compatible backend.
func StartPyroscope(cfg pyroscope.Config) (*pyroscope.Profiler, error) {
	return pyroscope.Start(cfg)
}

// StopPyroscope stops the profiler session (flush remaining samples).
func StopPyroscope(p *pyroscope.Profiler) error {
	if p == nil {
		return nil
	}
	return p.Stop()
}

// TagWrapper runs cb with pprof labels (shown as tags in flamegraphs).
func TagWrapper(ctx context.Context, labels pyroscope.LabelSet, cb func(context.Context)) {
	pyroscope.TagWrapper(ctx, labels, cb)
}
