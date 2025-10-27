package main

import (
	"context"
	"encoding/json"
	"fmt"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/gofiber/fiber/v2"
	"github.com/gofiber/fiber/v2/middleware/cors"
	"github.com/gofiber/fiber/v2/middleware/helmet"
	"github.com/gofiber/fiber/v2/middleware/recover"
	"go.uber.org/zap"
)

func main() {
	// Initialize logger
	zapLogger, _ := zap.NewProduction()
	defer zapLogger.Sync()
	logger := zapLogger.Sugar()

	// Create Fiber app with optimized config for high traffic
	app := fiber.New(fiber.Config{
		Prefork:       false, // Enable for production multi-core scaling
		CaseSensitive: true,
		StrictRouting: false,
		ServerHeader:  "Rice-DB-Service",
		AppName:       "Rice Database Service v1.0",
		BodyLimit:     4 * 1024 * 1024, // 4MB
		ReadTimeout:   5 * time.Second,
		WriteTimeout:  10 * time.Second,
		IdleTimeout:   120 * time.Second,
		// Use fastest JSON library
		JSONEncoder: json.Marshal,
		JSONDecoder: json.Unmarshal,
	})

	// Middleware
	app.Use(recover.New())
	app.Use(logger.New())
	app.Use(cors.New(cors.Config{
		AllowOrigins:     []string{"*"},
		AllowMethods:     []string{"GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"},
		AllowHeaders:     []string{"Origin", "Content-Type", "Accept", "Authorization"},
		ExposeHeaders:    []string{"Content-Length"},
		AllowCredentials: true,
		MaxAge:           12 * 3600,
	}))
	app.Use(helmet.New())

	// Health check endpoint
	app.Get("/health", func(c fiber.Ctx) error {
		return c.JSON(fiber.Map{
			"status":    "ok",
			"service":   "rice-db",
			"timestamp": time.Now().Unix(),
			"uptime":    time.Since(startTime).Seconds(),
		})
	})

	// API v1 routes
	v1 := app.Group("/api/v1")

	// Auth routes
	auth := v1.Group("/auth")
	auth.Post("/register", handleRegister)
	auth.Post("/login", handleLogin)
	auth.Post("/refresh", handleRefreshToken)
	auth.Post("/logout", handleLogout)
	auth.Get("/me", authMiddleware, handleGetMe)

	// User routes (protected)
	users := v1.Group("/users", authMiddleware)
	users.Get("/", handleListUsers)
	users.Get("/:id", handleGetUser)
	users.Put("/:id", handleUpdateUser)
	users.Delete("/:id", handleDeleteUser)

	// Metrics endpoint (Prometheus)
	app.Get("/metrics", handleMetrics)

	// 404 handler
	app.Use(func(c fiber.Ctx) error {
		return c.Status(fiber.StatusNotFound).JSON(fiber.Map{
			"error": "Route not found",
		})
	})

	// Server configuration
	port := getEnv("PORT", "8080")
	addr := fmt.Sprintf("0.0.0.0:%s", port)

	// Graceful shutdown
	quit := make(chan os.Signal, 1)
	signal.Notify(quit, os.Interrupt, syscall.SIGTERM)

	go func() {
		<-quit
		logger.Info("Shutting down server...")

		ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
		defer cancel()

		if err := app.ShutdownWithContext(ctx); err != nil {
			logger.Errorf("Server forced to shutdown: %v", err)
		}
	}()

	// Start server
	logger.Infof("🚀 Server starting on %s", addr)
	logger.Infof("📊 Metrics available at http://%s/metrics", addr)
	logger.Infof("🏥 Health check at http://%s/health", addr)

	if err := app.Listen(addr); err != nil {
		logger.Fatalf("Failed to start server: %v", err)
	}
}

var startTime = time.Now()

// Placeholder handlers (implement these with actual logic)
func handleRegister(c fiber.Ctx) error {
	return c.Status(fiber.StatusCreated).JSON(fiber.Map{
		"message": "User registered successfully",
	})
}

func handleLogin(c fiber.Ctx) error {
	return c.JSON(fiber.Map{
		"token": "jwt-token-here",
		"user": fiber.Map{
			"id":    "user-123",
			"email": "user@example.com",
		},
	})
}

func handleRefreshToken(c fiber.Ctx) error {
	return c.JSON(fiber.Map{
		"token": "new-jwt-token-here",
	})
}

func handleLogout(c fiber.Ctx) error {
	return c.JSON(fiber.Map{
		"message": "Logged out successfully",
	})
}

func handleGetMe(c fiber.Ctx) error {
	return c.JSON(fiber.Map{
		"id":    "user-123",
		"email": "user@example.com",
		"role":  "user",
	})
}

func handleListUsers(c fiber.Ctx) error {
	return c.JSON(fiber.Map{
		"users": []fiber.Map{},
		"total": 0,
	})
}

func handleGetUser(c fiber.Ctx) error {
	id := c.Params("id")
	return c.JSON(fiber.Map{
		"id":    id,
		"email": "user@example.com",
	})
}

func handleUpdateUser(c fiber.Ctx) error {
	return c.JSON(fiber.Map{
		"message": "User updated",
	})
}

func handleDeleteUser(c fiber.Ctx) error {
	return c.Status(fiber.StatusNoContent).Send(nil)
}

func handleMetrics(c fiber.Ctx) error {
	// TODO: Integrate Prometheus metrics
	return c.SendString("# Prometheus metrics here")
}

func authMiddleware(c fiber.Ctx) error {
	// TODO: Implement JWT validation
	token := c.Get("Authorization")
	if token == "" {
		return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{
			"error": "Unauthorized",
		})
	}
	return c.Next()
}

func getEnv(key, fallback string) string {
	if value, ok := os.LookupEnv(key); ok {
		return value
	}
	return fallback
}
