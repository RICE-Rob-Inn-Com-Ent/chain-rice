package router

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
	fiberLogger "github.com/gofiber/fiber/v2/middleware/logger"
	"github.com/gofiber/fiber/v2/middleware/recover"
	"go.uber.org/zap"

	"github.com/chainrice/rice/backend/app/helpers"
)

var apiServerStartTime = time.Now()
var graphqlServerStartTime = time.Now()

// RunAPIServer starts the API server
func RunAPIServer() {
	zapLogger, _ := zap.NewProduction()
	defer zapLogger.Sync()
	logger := zapLogger.Sugar()

	projectName := helpers.GetEnv("PROJECT_NAME", "Database Service")
	projectSlug := helpers.GetEnv("PROJECT_SLUG", "db")
	serviceName := helpers.GetEnv("SERVICE_NAME", fmt.Sprintf("%s-db-service", projectSlug))

	app := fiber.New(fiber.Config{
		Prefork:       false,
		CaseSensitive: true,
		StrictRouting: false,
		ServerHeader:  fmt.Sprintf("%s-DB-Service", projectName),
		AppName:       fmt.Sprintf("%s Database Service v1.0", projectName),
		BodyLimit:     4 * 1024 * 1024,
		ReadTimeout:   5 * time.Second,
		WriteTimeout:  10 * time.Second,
		IdleTimeout:   120 * time.Second,
		JSONEncoder:   json.Marshal,
		JSONDecoder:   json.Unmarshal,
	})

	app.Use(recover.New())
	app.Use(fiberLogger.New())

	corsOrigins := helpers.GetEnv("CORS_ALLOWED_ORIGINS", "")
	corsAllowAll := helpers.GetEnv("CORS_ALLOW_ALL", "false")

	corsConfig := cors.Config{
		AllowMethods:  "GET,POST,PUT,PATCH,DELETE,OPTIONS",
		AllowHeaders:  "Origin,Content-Type,Accept,Authorization",
		ExposeHeaders: "Content-Length",
		MaxAge:        12 * 3600,
	}

	if corsAllowAll == "true" {
		corsConfig.AllowOrigins = "*"
		corsConfig.AllowCredentials = false
	} else if corsOrigins != "" {
		corsConfig.AllowOrigins = corsOrigins
		corsConfig.AllowCredentials = true
	} else {
		corsConfig.AllowOrigins = ""
		corsConfig.AllowCredentials = false
	}

	app.Use(cors.New(corsConfig))
	app.Use(helmet.New())

	app.Get("/health", func(c *fiber.Ctx) error {
		return c.JSON(fiber.Map{
			"status":    "ok",
			"service":   serviceName,
			"project":   projectSlug,
			"timestamp": time.Now().Unix(),
			"uptime":    time.Since(apiServerStartTime).Seconds(),
		})
	})

	v1 := app.Group("/api/v1")

	auth := v1.Group("/auth")
	auth.Post("/register", handleAPIRegister)
	auth.Post("/login", handleAPILogin)
	auth.Post("/refresh", handleAPIRefreshToken)
	auth.Post("/logout", handleAPILogout)
	auth.Get("/me", apiAuthMiddleware, handleAPIGetMe)

	users := v1.Group("/users", apiAuthMiddleware)
	users.Get("/", handleAPIListUsers)
	users.Get("/:id", handleAPIGetUser)
	users.Put("/:id", handleAPIUpdateUser)
	users.Delete("/:id", handleAPIDeleteUser)

	app.Get("/metrics", handleAPIMetrics)

	app.Use(func(c *fiber.Ctx) error {
		return c.Status(fiber.StatusNotFound).JSON(fiber.Map{
			"error": "Route not found",
		})
	})

	port := helpers.GetEnv("PORT", "8080")
	addr := fmt.Sprintf("0.0.0.0:%s", port)

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

	logger.Infof("🚀 Server starting on %s", addr)
	logger.Infof("📊 Metrics available at http://%s/metrics", addr)
	logger.Infof("🏥 Health check at http://%s/health", addr)

	if err := app.Listen(addr); err != nil {
		logger.Fatalf("Failed to start server: %v", err)
	}
}

// RunGraphQLServer starts the GraphQL server
func RunGraphQLServer() {
	zapLogger, _ := zap.NewProduction()
	defer zapLogger.Sync()
	logger := zapLogger.Sugar()

	app := fiber.New(fiber.Config{
		Prefork:       false,
		CaseSensitive: true,
		StrictRouting: false,
		ServerHeader:  "GraphQL-Router",
		AppName:       "GraphQL Router Service v1.0",
		BodyLimit:     4 * 1024 * 1024,
		ReadTimeout:   5 * time.Second,
		WriteTimeout:  10 * time.Second,
		IdleTimeout:   120 * time.Second,
		JSONEncoder:   json.Marshal,
		JSONDecoder:   json.Unmarshal,
	})

	app.Use(recover.New())
	app.Use(fiberLogger.New())
	app.Use(cors.New(cors.Config{
		AllowOrigins:     "*",
		AllowMethods:     "GET,POST,OPTIONS",
		AllowHeaders:     "Origin,Content-Type,Accept,Authorization",
		ExposeHeaders:    "Content-Length",
		AllowCredentials: false,
		MaxAge:           12 * 3600,
	}))
	app.Use(helmet.New())

	app.Get("/health", func(c *fiber.Ctx) error {
		return c.JSON(fiber.Map{
			"status":    "ok",
			"service":   "graphql",
			"timestamp": time.Now().Unix(),
			"uptime":    time.Since(graphqlServerStartTime).Seconds(),
		})
	})

	app.Post("/graphql", func(c *fiber.Ctx) error {
		return c.JSON(fiber.Map{
			"data": fiber.Map{
				"status": "GraphQL endpoint placeholder",
			},
		})
	})

	app.Get("/", func(c *fiber.Ctx) error {
		return c.JSON(fiber.Map{
			"service": "graphql",
			"status":  "running",
			"endpoints": fiber.Map{
				"health":  "/health",
				"graphql": "/graphql",
			},
		})
	})

	port := helpers.GetEnv("PORT", "4000")
	addr := fmt.Sprintf("0.0.0.0:%s", port)

	quit := make(chan os.Signal, 1)
	signal.Notify(quit, os.Interrupt, syscall.SIGTERM)

	go func() {
		<-quit
		logger.Info("Shutting down GraphQL server...")

		ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
		defer cancel()

		if err := app.ShutdownWithContext(ctx); err != nil {
			logger.Errorf("Server forced to shutdown: %v", err)
		}
	}()

	logger.Infof("✅ GraphQL service listening on %s", addr)
	logger.Infof("🏥 Health check at http://%s/health", addr)
	logger.Infof("🔌 GraphQL endpoint at http://%s/graphql", addr)

	if err := app.Listen(addr); err != nil {
		logger.Fatalf("Failed to start server: %v", err)
	}
}

// API server handlers
func handleAPIRegister(c *fiber.Ctx) error {
	return c.Status(fiber.StatusCreated).JSON(fiber.Map{
		"message": "User registered successfully",
	})
}

func handleAPILogin(c *fiber.Ctx) error {
	return c.JSON(fiber.Map{
		"token": "jwt-token-here",
		"user": fiber.Map{
			"id":    "user-123",
			"email": "user@example.com",
		},
	})
}

func handleAPIRefreshToken(c *fiber.Ctx) error {
	return c.JSON(fiber.Map{
		"token": "new-jwt-token-here",
	})
}

func handleAPILogout(c *fiber.Ctx) error {
	return c.JSON(fiber.Map{
		"message": "Logged out successfully",
	})
}

func handleAPIGetMe(c *fiber.Ctx) error {
	return c.JSON(fiber.Map{
		"id":    "user-123",
		"email": "user@example.com",
		"role":  "user",
	})
}

func handleAPIListUsers(c *fiber.Ctx) error {
	return c.JSON(fiber.Map{
		"users": []fiber.Map{},
		"total": 0,
	})
}

func handleAPIGetUser(c *fiber.Ctx) error {
	id := c.Params("id")
	return c.JSON(fiber.Map{
		"id":    id,
		"email": "user@example.com",
	})
}

func handleAPIUpdateUser(c *fiber.Ctx) error {
	return c.JSON(fiber.Map{
		"message": "User updated",
	})
}

func handleAPIDeleteUser(c *fiber.Ctx) error {
	return c.Status(fiber.StatusNoContent).Send(nil)
}

func handleAPIMetrics(c *fiber.Ctx) error {
	return c.SendString("# Prometheus metrics here")
}

func apiAuthMiddleware(c *fiber.Ctx) error {
	token := c.Get("Authorization")
	if token == "" {
		return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{
			"error": "Unauthorized",
		})
	}
	return c.Next()
}
