package observability

import (
	"net/http"

	"github.com/prometheus/client_golang/prometheus"
	"github.com/prometheus/client_golang/prometheus/promhttp"
	"go.uber.org/zap"
)

// Registry wraps Prometheus registry and zap logger for easy DI.
type Registry struct {
	Prom *prometheus.Registry
	Log  *zap.Logger
}

func NewRegistry() (*Registry, error) {
	reg := prometheus.NewRegistry()
	log, err := zap.NewProduction()
	if err != nil {
		return nil, err
	}
	return &Registry{Prom: reg, Log: log}, nil
}

func (r *Registry) MetricsHandler() http.Handler {
	return promhttp.HandlerFor(r.Prom, promhttp.HandlerOpts{})
}