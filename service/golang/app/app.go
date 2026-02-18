package app

import (
	"context"
	"encoding/json"
	"fmt"
	"net/http"
	"os"
	"os/signal"
	"strconv"
	"strings"
	"syscall"
	"time"

	"github.com/gofiber/fiber/v2"
	"github.com/gofiber/fiber/v2/middleware/cors"
	"github.com/gofiber/fiber/v2/middleware/helmet"
	fiberLogger "github.com/gofiber/fiber/v2/middleware/logger"
	"github.com/gofiber/fiber/v2/middleware/recover"
	"github.com/prometheus/client_golang/prometheus"
	"github.com/prometheus/client_golang/prometheus/promhttp"
	"github.com/valyala/fasthttp/fasthttpadaptor"
	"go.uber.org/zap"

	"github.com/chainrice/rice/backend/app/router"
	"github.com/chainrice/rice/backend/app/auth"
	"github.com/chainrice/rice/backend/app/secrets"
	"github.com/chainrice/rice/backend/app/middleware"
)

var startTime = time.Now()

// ============================================================================
// Constants
// ============================================================================

const (
	// Container names
	containerNamePostgres = "devcontainer-postgres"
	containerNameMongoDB  = "devcontainer-mongodb"

	// Docker restart policy
	restartPolicyUnlessStopped = "unless-stopped"

	// Default test email
	defaultTestEmail = "user@example.com"

	// Default test user ID
	defaultTestUserID = "user-123"

	// Error messages
	ErrInvalidRequestBody         = "Invalid request body"
	ErrFailedGenerateAccessToken   = "Failed to generate access token"
	ErrFailedGenerateRefreshToken  = "Failed to generate refresh token"
)

// ============================================================================
// Router Configuration (re-export from router package)
// ============================================================================

// RouterConfig represents router configuration
// This is a re-export of router.Config for convenience
type RouterConfig = router.Config

// New creates and starts a new router service
// This is a re-export of router.New for convenience
func New(cfg RouterConfig) {
	router.New(router.Config(cfg))
}

// CheckHealth checks if a URL is healthy
// This is a re-export of router.CheckHealth for convenience
func CheckHealth(client *http.Client, url string) bool {
	return router.CheckHealth(client, url)
}

// GetEnv gets environment variable or returns fallback
func GetEnv(key, fallback string) string {
	if value, ok := os.LookupEnv(key); ok {
		return value
	}
	return fallback
}

func getEnv(key, fallback string) string {
	return GetEnv(key, fallback)
}

// ============================================================================
// Application Configuration
// ============================================================================

// Config holds application configuration
// All values are loaded from environment variables with sensible defaults
type Config struct {
	// Application metadata
	ProjectName string
	ProjectSlug string
	ServiceName string
	Version     string
	Environment string // development, staging, production

	// Server configuration
	Port          string
	Host          string
	ReadTimeout   time.Duration
	WriteTimeout  time.Duration
	IdleTimeout   time.Duration
	BodyLimit     int64
	Prefork       bool
	CaseSensitive bool
	StrictRouting bool

	// CORS configuration
	AllowedOrigins       []string
	CORSAllowAll         bool
	CORSAllowMethods     string
	CORSAllowHeaders     string
	CORSExposeHeaders    string
	CORSMaxAge           int
	CORSAllowCredentials bool

	// Security
	EnableHelmet bool
	EnableLogger bool

	// Logging
	LogLevel  string
	LogFormat string // json, text

	// API configuration
	APIPrefix string // API prefix (e.g., "/api/v1")
}

// DefaultConfig returns default application configuration
func DefaultConfig() Config {
	return Config{
		ProjectName:          getEnv("PROJECT_NAME", "Database Service"),
		ProjectSlug:          getEnv("PROJECT_SLUG", "db"),
		ServiceName:          getEnv("SERVICE_NAME", getEnv("PROJECT_SLUG", "db")+"-service"),
		Version:              getEnv("SERVICE_VERSION", "1.0.0"),
		Environment:          getEnv("ENVIRONMENT", "development"),
		Port:                 getEnv("PORT", "8080"),
		Host:                 getEnv("HOST", "0.0.0.0"),
		ReadTimeout:          parseDuration(getEnv("READ_TIMEOUT", "5s"), 5*time.Second),
		WriteTimeout:         parseDuration(getEnv("WRITE_TIMEOUT", "10s"), 10*time.Second),
		IdleTimeout:          parseDuration(getEnv("IDLE_TIMEOUT", "120s"), 120*time.Second),
		BodyLimit:            parseInt64(getEnv("BODY_LIMIT", "4194304"), 4*1024*1024), // 4MB
		Prefork:              getEnvBool("PREFORK", false),
		CaseSensitive:        getEnvBool("CASE_SENSITIVE", true),
		StrictRouting:        getEnvBool("STRICT_ROUTING", false),
		AllowedOrigins:       parseStringSlice(getEnv("CORS_ALLOWED_ORIGINS", "http://localhost:3000,http://localhost:3001")),
		CORSAllowAll:         getEnvBool("CORS_ALLOW_ALL", false),
		CORSAllowMethods:     getEnv("CORS_ALLOW_METHODS", "GET,POST,PUT,PATCH,DELETE,OPTIONS"),
		CORSAllowHeaders:     getEnv("CORS_ALLOW_HEADERS", "Origin,Content-Type,Accept,Authorization"),
		CORSExposeHeaders:    getEnv("CORS_EXPOSE_HEADERS", "Content-Length"),
		CORSMaxAge:           parseInt(getEnv("CORS_MAX_AGE", "43200"), 12*3600),
		CORSAllowCredentials: !getEnvBool("CORS_ALLOW_ALL", false), // Disable if wildcard
		EnableHelmet:         getEnvBool("ENABLE_HELMET", true),
		EnableLogger:         getEnvBool("ENABLE_LOGGER", true),
		LogLevel:             getEnv("LOG_LEVEL", "info"),
		LogFormat:            getEnv("LOG_FORMAT", "json"),
		APIPrefix:            getEnv("API_PREFIX", "/api/v1"),
	}
}

// FromEnv creates config from environment variables
func FromEnv() Config {
	return DefaultConfig()
}

// ============================================================================
// Cloud Provider Detection
// ============================================================================
// Note: Cloud provider types and functions are in app/services package
// to avoid import cycles. Import app/services directly when needed.

// ============================================================================
// Service Orchestration Types
// ============================================================================
// Note: Orchestration types have been moved to app/orchestration package
// Import app/orchestration for Service, Orchestrator, etc.

// ============================================================================
// Application
// ============================================================================

// App represents the main application
type App struct {
	Fiber        *fiber.App
	Config       Config
	Logger       *zap.SugaredLogger
	Registry     *prometheus.Registry
	JWTService   *auth.JWTService
	UserService  *auth.UserService
	SecretManager secrets.SecretManager
}

// NewApp creates a new application instance
func NewApp(config Config) *App {
	// Initialize logger based on config
	var zapLogger *zap.Logger
	var err error

	if config.LogFormat == "json" {
		zapLogger, err = zap.NewProduction()
	} else {
		zapLogger, err = zap.NewDevelopment()
	}
	if err != nil {
		// Fallback to production logger if initialization fails
		zapLogger, _ = zap.NewProduction()
	}
	logger := zapLogger.Sugar()

	// Create Fiber app with config from environment variables
	fiberApp := fiber.New(fiber.Config{
		Prefork:       config.Prefork,
		CaseSensitive: config.CaseSensitive,
		StrictRouting: config.StrictRouting,
		ServerHeader:  fmt.Sprintf("%s-Service", config.ProjectName),
		AppName:       fmt.Sprintf("%s v%s", config.ProjectName, config.Version),
		BodyLimit:     int(config.BodyLimit),
		ReadTimeout:   config.ReadTimeout,
		WriteTimeout:  config.WriteTimeout,
		IdleTimeout:   config.IdleTimeout,
		// Use fastest JSON library
		JSONEncoder: json.Marshal,
		JSONDecoder: json.Unmarshal,
	})

	// Middleware
	fiberApp.Use(recover.New())
	if config.EnableLogger {
		fiberApp.Use(fiberLogger.New())
	}

	// CORS configuration - all from config
	corsConfig := cors.Config{
		AllowMethods:  config.CORSAllowMethods,
		AllowHeaders:  config.CORSAllowHeaders,
		ExposeHeaders: config.CORSExposeHeaders,
		MaxAge:        config.CORSMaxAge,
	}

	// Set allowed origins from config
	if config.CORSAllowAll {
		// Only allow wildcard if explicitly set (development only)
		corsConfig.AllowOrigins = "*"
		corsConfig.AllowCredentials = false // Cannot use credentials with wildcard
	} else if len(config.AllowedOrigins) > 0 {
		// Use whitelist of allowed origins
		corsConfig.AllowOrigins = strings.Join(config.AllowedOrigins, ",")
		corsConfig.AllowCredentials = config.CORSAllowCredentials
	} else {
		// Default: no CORS (most secure)
		corsConfig.AllowOrigins = ""
		corsConfig.AllowCredentials = false
	}

	fiberApp.Use(cors.New(corsConfig))
	if config.EnableHelmet {
		fiberApp.Use(helmet.New())
	}

	// Initialize Prometheus registry
	registry := prometheus.NewRegistry()
	registry.MustRegister(prometheus.NewGoCollector())
	registry.MustRegister(prometheus.NewProcessCollector(prometheus.ProcessCollectorOpts{}))

	// Initialize secret manager
	secretManager := secrets.GetSecretManager(logger)

	// Initialize JWT service
	jwtSecret, _ := secretManager.GetSecret(context.Background(), "JWT_SECRET_KEY")
	if jwtSecret == "" {
		jwtSecret = getEnv("JWT_SECRET_KEY", "default-secret-key-change-in-production-minimum-32-characters-long")
	}

	jwtService, err := auth.NewJWTService(auth.JWTConfig{
		SecretKey:     jwtSecret,
		AccessExpiry:  15 * time.Minute,
		RefreshExpiry: 7 * 24 * time.Hour,
		Logger:        logger,
	})
	if err != nil {
		logger.Warnf("Failed to initialize JWT service: %v", err)
	}

	// Initialize user service
	userRepo := auth.NewInMemoryUserRepository()
	userService := auth.NewUserService(userRepo, logger)

	app := &App{
		Fiber:         fiberApp,
		Config:        config,
		Logger:        logger,
		Registry:      registry,
		JWTService:     jwtService,
		UserService:   userService,
		SecretManager: secretManager,
	}

	app.setupRoutes()

	return app
}

// setupRoutes configures all application routes
func (a *App) setupRoutes() {
	// Health check endpoint
	a.Fiber.Get("/health", func(c *fiber.Ctx) error {
		return c.JSON(fiber.Map{
			"status":    "ok",
			"service":   a.Config.ServiceName,
			"project":   a.Config.ProjectSlug,
			"version":   a.Config.Version,
			"timestamp": time.Now().Unix(),
			"uptime":    time.Since(startTime).Seconds(),
		})
	})

	// API routes - prefix from config
	v1 := a.Fiber.Group(a.Config.APIPrefix)

	// Apply rate limiting to all API routes
	v1.Use(middleware.RateLimit(middleware.DefaultRateLimitConfig()))

	// Auth routes (with stricter rate limiting)
	authGroup := v1.Group("/auth")
	authGroup.Use(middleware.AuthRateLimit())
	authGroup.Post("/register", a.handleRegister)
	authGroup.Post("/login", a.handleLogin)
	authGroup.Post("/refresh", a.handleRefreshToken)
	authGroup.Post("/logout", a.handleLogout)
	authGroup.Get("/me", middleware.JWTAuth(a.JWTService), a.handleGetMe)

	// User routes (protected with JWT)
	users := v1.Group("/users", middleware.JWTAuth(a.JWTService))
	users.Get("/", a.handleListUsers)
	users.Get("/:id", a.handleGetUser)
	users.Put("/:id", a.handleUpdateUser)
	users.Delete("/:id", a.handleDeleteUser)

	// Metrics endpoint (Prometheus)
	a.Fiber.Get("/metrics", a.handleMetrics)

	// 404 handler
	a.Fiber.Use(func(c *fiber.Ctx) error {
		return c.Status(fiber.StatusNotFound).JSON(fiber.Map{
			"error":  "Route not found",
			"path":   c.Path(),
			"method": c.Method(),
		})
	})
}

// Listen starts the server
func (a *App) Listen() error {
	if a == nil {
		return fmt.Errorf("app cannot be nil")
	}

	if a.Fiber == nil {
		return fmt.Errorf("fiber app cannot be nil")
	}

	if a.Config.Port == "" {
		return fmt.Errorf("port cannot be empty")
	}

	if a.Config.Host == "" {
		return fmt.Errorf("host cannot be empty")
	}

	addr := fmt.Sprintf("%s:%s", a.Config.Host, a.Config.Port)

	// Graceful shutdown
	quit := make(chan os.Signal, 1)
	signal.Notify(quit, os.Interrupt, syscall.SIGTERM)

	go func() {
		<-quit
		if a.Logger != nil {
			a.Logger.Info("Shutting down server...")
		}

		ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
		defer cancel()

		if err := a.Fiber.ShutdownWithContext(ctx); err != nil {
			if a.Logger != nil {
				a.Logger.Errorf("Server forced to shutdown: %v", err)
			}
		}
	}()

	// Start server
	if a.Logger != nil {
		a.Logger.Infof("🚀 Server starting on %s", addr)
		a.Logger.Infof("📊 Metrics available at http://%s/metrics", addr)
		a.Logger.Infof("🏥 Health check at http://%s/health", addr)
	}

	return a.Fiber.Listen(addr)
}

// Auth request/response types
type RegisterRequest struct {
	Email    string `json:"email" validate:"required,email"`
	Name     string `json:"name" validate:"required,min=2,max=100"`
	Password string `json:"password" validate:"required,min=8"`
}

type LoginRequest struct {
	Email    string `json:"email" validate:"required,email"`
	Password string `json:"password" validate:"required"`
}

type RefreshTokenRequest struct {
	RefreshToken string `json:"refresh_token" validate:"required"`
}

type AuthResponse struct {
	AccessToken  string      `json:"access_token"`
	RefreshToken string      `json:"refresh_token"`
	User         *auth.User  `json:"user"`
}

// handleRegister handles user registration
func (a *App) handleRegister(c *fiber.Ctx) error {
	var req RegisterRequest
	if err := c.BodyParser(&req); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"error": ErrInvalidRequestBody,
		})
	}

	// Validate password strength
	if err := auth.ValidatePasswordStrength(req.Password); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"error": err.Error(),
		})
	}

	// Create user
	user, err := a.UserService.CreateUser(c.Context(), req.Email, req.Name, req.Password)
	if err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"error": err.Error(),
		})
	}

	// Generate tokens
	accessToken, err := a.JWTService.GenerateAccessToken(user.ID, user.Email, user.Roles)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
			"error": ErrFailedGenerateAccessToken,
		})
	}

	refreshToken, err := a.JWTService.GenerateRefreshToken(user.ID, user.Email, user.Roles)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
			"error": ErrFailedGenerateRefreshToken,
		})
	}

	return c.Status(fiber.StatusCreated).JSON(AuthResponse{
		AccessToken:  accessToken,
		RefreshToken: refreshToken,
		User:         user,
	})
}

// handleLogin handles user login
func (a *App) handleLogin(c *fiber.Ctx) error {
	var req LoginRequest
	if err := c.BodyParser(&req); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"error": ErrInvalidRequestBody,
		})
	}

	// Authenticate user
	user, err := a.UserService.AuthenticateUser(c.Context(), req.Email, req.Password)
	if err != nil {
		return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{
			"error": "Invalid credentials",
		})
	}

	// Generate tokens
	accessToken, err := a.JWTService.GenerateAccessToken(user.ID, user.Email, user.Roles)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
			"error": ErrFailedGenerateAccessToken,
		})
	}

	refreshToken, err := a.JWTService.GenerateRefreshToken(user.ID, user.Email, user.Roles)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
			"error": ErrFailedGenerateRefreshToken,
		})
	}

	return c.JSON(AuthResponse{
		AccessToken:  accessToken,
		RefreshToken: refreshToken,
		User:         user,
	})
}

// handleRefreshToken handles token refresh
func (a *App) handleRefreshToken(c *fiber.Ctx) error {
	var req RefreshTokenRequest
	if err := c.BodyParser(&req); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"error": ErrInvalidRequestBody,
		})
	}

	// Validate refresh token
	claims, err := a.JWTService.ValidateRefreshToken(req.RefreshToken)
	if err != nil {
		return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{
			"error": "Invalid or expired refresh token",
		})
	}

	// Get user
	user, err := a.UserService.GetUser(c.Context(), claims.UserID)
	if err != nil {
		return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{
			"error": "User not found",
		})
	}

	// Generate new tokens
	accessToken, err := a.JWTService.GenerateAccessToken(user.ID, user.Email, user.Roles)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
			"error": ErrFailedGenerateAccessToken,
		})
	}

	refreshToken, err := a.JWTService.GenerateRefreshToken(user.ID, user.Email, user.Roles)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
			"error": ErrFailedGenerateRefreshToken,
		})
	}

	return c.JSON(AuthResponse{
		AccessToken:  accessToken,
		RefreshToken: refreshToken,
		User:         user,
	})
}

// handleLogout handles user logout
func (a *App) handleLogout(c *fiber.Ctx) error {
	// In a production system, you would invalidate the refresh token
	// For now, we just return success
	return c.JSON(fiber.Map{
		"message": "Logged out successfully",
	})
}

// handleGetMe returns current user information
func (a *App) handleGetMe(c *fiber.Ctx) error {
	userID := c.Locals("userID").(string)

	user, err := a.UserService.GetUser(c.Context(), userID)
	if err != nil {
		return c.Status(fiber.StatusNotFound).JSON(fiber.Map{
			"error": "User not found",
		})
	}

	return c.JSON(user)
}

func (a *App) handleListUsers(c *fiber.Ctx) error {
	return c.JSON(fiber.Map{
		"users": []fiber.Map{},
		"total": 0,
	})
}

func (a *App) handleGetUser(c *fiber.Ctx) error {
	id := c.Params("id")
	return c.JSON(fiber.Map{
		"id":    id,
		"email": defaultTestEmail,
	})
}

func (a *App) handleUpdateUser(c *fiber.Ctx) error {
	return c.JSON(fiber.Map{
		"message": "User updated",
	})
}

func (a *App) handleDeleteUser(c *fiber.Ctx) error {
	return c.Status(fiber.StatusNoContent).Send(nil)
}

func (a *App) handleMetrics(c *fiber.Ctx) error {
	// Prometheus metrics handler - adapt standard http handler for Fiber
	handler := promhttp.HandlerFor(a.Registry, promhttp.HandlerOpts{
		EnableOpenMetrics: true,
	})

	// Use fasthttp adaptor to bridge between Fiber and standard http handler
	adaptor := fasthttpadaptor.NewFastHTTPHandler(handler)
	adaptor(c.Context())
	return nil
}


// ============================================================================
// Helper Functions
// ============================================================================

func getEnvBool(key string, defaultValue bool) bool {
	value := os.Getenv(key)
	if value == "" {
		return defaultValue
	}
	return strings.ToLower(value) == "true" || value == "1"
}

func parseInt(s string, defaultValue int) int {
	if s == "" {
		return defaultValue
	}
	if val, err := strconv.Atoi(s); err == nil {
		return val
	}
	return defaultValue
}

func parseInt64(s string, defaultValue int64) int64 {
	if s == "" {
		return defaultValue
	}
	if val, err := strconv.ParseInt(s, 10, 64); err == nil {
		return val
	}
	return defaultValue
}

func parseDuration(s string, defaultValue time.Duration) time.Duration {
	if s == "" {
		return defaultValue
	}
	if d, err := time.ParseDuration(s); err == nil {
		return d
	}
	return defaultValue
}

func parseStringSlice(s string) []string {
	if s == "" {
		return []string{}
	}
	parts := strings.Split(s, ",")
	result := make([]string, 0, len(parts))
	for _, part := range parts {
		part = strings.TrimSpace(part)
		if part != "" {
			result = append(result, part)
		}
	}
	return result
}

// ============================================================================
// Orchestrator Methods
// ============================================================================
// Note: Orchestrator functionality has been moved to app/orchestration package
// Use orchestration.NewOrchestrator() instead

// ============================================================================
// Router Re-exports (for backward compatibility)
// ============================================================================

// Re-export router functions to maintain public API
func RunAPIServer() {
	router.RunAPIServer()
}

func RunGraphQLServer() {
	router.RunGraphQLServer()
}

func RunAdminRouter() {
	router.RunAdminRouter()
}

func RunDatabaseRouter() {
	router.RunDatabaseRouter()
}

func RunMonitoringRouter() {
	router.RunMonitoringRouter()
}

func RunTraefikProxy() {
	router.RunTraefikProxy()
}

func RunElasticsearchProxy() {
	router.RunElasticsearchProxy()
}
