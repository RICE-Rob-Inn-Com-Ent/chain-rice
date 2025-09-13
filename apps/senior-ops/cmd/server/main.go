package main

import (
	"context"
	"fmt"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"go.uber.org/zap"

	appsvc "github.com/example/senior-ops/internal/app"
	adapthttp "github.com/example/senior-ops/internal/adapters/http"
	"github.com/example/senior-ops/internal/observability"
)

func main() {
	obs, err := observability.NewRegistry()
	if err != nil {
		panic(err)
	}
	log := obs.Log
	defer log.Sync() // nolint:errcheck

	repo := appsvc.NewInMemoryRepo()
	svc := appsvc.NewService(repo, obs.Prom)

	addrHTTP := env("SENIOR_OPS_HTTP_ADDR", ":8088")

	httpServer := adapthttp.NewServer(log, obs, svc, addrHTTP)
	server := httpServer.Start()

	// TODO: gRPC server on :9098 and graceful shutdown for both

	ctx, stop := signal.NotifyContext(context.Background(), syscall.SIGTERM, syscall.SIGINT)
	defer stop()
	<-ctx.Done()

	shutdownCtx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()
	if err := server.Shutdown(shutdownCtx); err != nil {
		log.Error("http shutdown error", zap.Error(err))
	} else {
		log.Info("http server shutdown")
	}
}

func env(key, def string) string {
	if v := os.Getenv(key); v != "" {
		return v
	}
	return def
}