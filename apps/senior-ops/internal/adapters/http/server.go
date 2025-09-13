package http

import (
	"encoding/json"
	"net/http"
	"time"

	"github.com/go-chi/chi/v5"
	"github.com/go-chi/chi/v5/middleware"
	"github.com/prometheus/client_golang/prometheus"
	"go.uber.org/zap"

	appsvc "github.com/example/senior-ops/internal/app"
	"github.com/example/senior-ops/internal/observability"
)

type Server struct {
	log   *zap.Logger
	obs   *observability.Registry
	svc   *appsvc.Service
	addr  string
}

func NewServer(log *zap.Logger, obs *observability.Registry, svc *appsvc.Service, addr string) *Server {
	return &Server{log: log, obs: obs, svc: svc, addr: addr}
}

func (s *Server) Handler() http.Handler {
	r := chi.NewRouter()
	r.Use(middleware.RequestID)
	r.Use(middleware.RealIP)
	r.Use(middleware.Logger)
	r.Use(middleware.Recoverer)

	r.Get("/health", func(w http.ResponseWriter, r *http.Request) {
		_ = json.NewEncoder(w).Encode(map[string]any{"status": "ok", "time": time.Now()})
	})

	r.Handle("/metrics", s.obs.MetricsHandler())

	return r
}

func (s *Server) Start() *http.Server {
	hs := &http.Server{Addr: s.addr, Handler: s.Handler()}
	go func() {
		if err := hs.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			s.log.Error("http server error", zap.Error(err))
		}
	}()
	return hs
}