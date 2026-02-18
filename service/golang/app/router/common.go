package router

import (
	"context"
	"encoding/json"
	"fmt"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/gofiber/fiber/v2"
	"github.com/gofiber/fiber/v2/middleware/cors"
	"github.com/gofiber/fiber/v2/middleware/helmet"
	fiberLogger "github.com/gofiber/fiber/v2/middleware/logger"
	"github.com/gofiber/fiber/v2/middleware/recover"
	"go.uber.org/zap"
)

var startTime = time.Now()

// Config represents router configuration
type Config struct {
	Name        string
	Port        string
	ServiceName string
	HealthCheck func(*http.Client) map[string]interface{}
	Routes      func(*fiber.App)
}

// New creates and starts a new router service
func New(cfg Config) {
	zapLogger, _ := zap.NewProduction()
	defer zapLogger.Sync()
	logger := zapLogger.Sugar()

	app := fiber.New(fiber.Config{
		Prefork:       false,
		CaseSensitive: true,
		StrictRouting: false,
		ServerHeader:  cfg.Name,
		AppName:       fmt.Sprintf("%s v1.0", cfg.Name),
		BodyLimit:     10 * 1024 * 1024, // 10MB
		ReadTimeout:   10 * time.Second,
		WriteTimeout:  10 * time.Second,
		IdleTimeout:   120 * time.Second,
		JSONEncoder:   json.Marshal,
		JSONDecoder:   json.Unmarshal,
	})

	// Standard middleware
	app.Use(recover.New())
	app.Use(fiberLogger.New())
	app.Use(cors.New(cors.Config{
		AllowOrigins:     "*",
		AllowMethods:     "GET,POST,PUT,PATCH,DELETE,OPTIONS",
		AllowHeaders:     "Origin,Content-Type,Accept,Authorization",
		ExposeHeaders:    "Content-Length",
		AllowCredentials: true,
		MaxAge:           12 * 3600,
	}))
	app.Use(helmet.New())

	// Health check endpoint
	app.Get("/health", func(c *fiber.Ctx) error {
		client := &http.Client{Timeout: 5 * time.Second}
		services := cfg.HealthCheck(client)
		return c.JSON(fiber.Map{
			"status":    "ok",
			"service":   cfg.ServiceName,
			"timestamp": time.Now().Unix(),
			"uptime":    time.Since(startTime).Seconds(),
			"services":  services,
		})
	})

	// Custom routes
	if cfg.Routes != nil {
		cfg.Routes(app)
	}

	// Root endpoint
	app.Get("/", func(c *fiber.Ctx) error {
		return c.JSON(fiber.Map{
			"service": cfg.ServiceName,
			"status":  "running",
		})
	})

	// Graceful shutdown
	quit := make(chan os.Signal, 1)
	signal.Notify(quit, os.Interrupt, syscall.SIGTERM)

	go func() {
		<-quit
		logger.Infof("Shutting down %s...", cfg.Name)

		ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
		defer cancel()

		if err := app.ShutdownWithContext(ctx); err != nil {
			logger.Errorf("Server forced to shutdown: %v", err)
		}
	}()

	// Start server
	port := getEnv("PORT", cfg.Port)
	addr := fmt.Sprintf("0.0.0.0:%s", port)
	logger.Infof("✅ %s listening on %s", cfg.Name, addr)
	logger.Infof("🏥 Health check at http://%s/health", addr)

	if err := app.Listen(addr); err != nil {
		logger.Fatalf("Failed to start server: %v", err)
	}
}

// CheckHealth checks if a URL is healthy
func CheckHealth(client *http.Client, url string) bool {
	resp, err := client.Get(url)
	if err != nil {
		return false
	}
	defer resp.Body.Close()
	return resp.StatusCode < 500
}

func getEnv(key, fallback string) string {
	if value, ok := os.LookupEnv(key); ok {
		return value
	}
	return fallback
}
