package testutil

import (
	"bytes"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/gofiber/fiber/v2"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
	"go.uber.org/zap"

	"github.com/chainrice/rice/backend/app/auth"
)

const (
	testEmail       = "test@example.com"
	testUserID      = "user-123"
	contentType     = "Content-Type"
	applicationJSON = "application/json"
)

func TestAuthHandlers(t *testing.T) {
	// Setup
	logger, _ := zap.NewDevelopment()
	zapLogger := logger.Sugar()

	// Create JWT service
	jwtService, err := auth.NewJWTService(auth.JWTConfig{
		SecretKey:     "test-secret-key-minimum-32-characters-long",
		AccessExpiry:  15 * 60,       // 15 minutes in seconds
		RefreshExpiry: 7 * 24 * 3600, // 7 days in seconds
		Logger:        zapLogger,
	})
	require.NoError(t, err)

	// Create user service
	userRepo := auth.NewInMemoryUserRepository()
	userService := auth.NewUserService(userRepo, zapLogger)

	// Create app
	fiberApp := fiber.New(fiber.Config{
		ErrorHandler: func(c *fiber.Ctx, err error) error {
			code := fiber.StatusInternalServerError
			if e, ok := err.(*fiber.Error); ok {
				code = e.Code
			}
			return c.Status(code).JSON(fiber.Map{"error": err.Error()})
		},
	})

	// Setup routes
	api := fiberApp.Group("/api/v1")
	authGroup := api.Group("/auth")

	// Register handler
	authGroup.Post("/register", func(c *fiber.Ctx) error {
		var req struct {
			Email    string `json:"email"`
			Name     string `json:"name"`
			Password string `json:"password"`
		}
		if err := c.BodyParser(&req); err != nil {
			return c.Status(400).JSON(fiber.Map{"error": err.Error()})
		}

		user, err := userService.CreateUser(c.Context(), req.Email, req.Name, req.Password)
		if err != nil {
			return c.Status(400).JSON(fiber.Map{"error": err.Error()})
		}

		accessToken, _ := jwtService.GenerateAccessToken(user.ID, user.Email, user.Roles)
		refreshToken, _ := jwtService.GenerateRefreshToken(user.ID, user.Email, user.Roles)

		return c.JSON(fiber.Map{
			"access_token":  accessToken,
			"refresh_token": refreshToken,
			"user":          user,
		})
	})

	// Login handler
	authGroup.Post("/login", func(c *fiber.Ctx) error {
		var req struct {
			Email    string `json:"email"`
			Password string `json:"password"`
		}
		if err := c.BodyParser(&req); err != nil {
			return c.Status(400).JSON(fiber.Map{"error": err.Error()})
		}

		user, err := userService.AuthenticateUser(c.Context(), req.Email, req.Password)
		if err != nil {
			return c.Status(401).JSON(fiber.Map{"error": "Invalid credentials"})
		}

		accessToken, _ := jwtService.GenerateAccessToken(user.ID, user.Email, user.Roles)
		refreshToken, _ := jwtService.GenerateRefreshToken(user.ID, user.Email, user.Roles)

		return c.JSON(fiber.Map{
			"access_token":  accessToken,
			"refresh_token": refreshToken,
			"user":          user,
		})
	})

	t.Run("Register User", func(t *testing.T) {
		reqBody := map[string]string{
			"email":    testEmail,
			"name":     "Test User",
			"password": "TestPass123!",
		}
		body, _ := json.Marshal(reqBody)

		req := httptest.NewRequest(http.MethodPost, "/api/v1/auth/register", bytes.NewBuffer(body))
		req.Header.Set(contentType, applicationJSON)
		resp, err := fiberApp.Test(req)
		require.NoError(t, err)
		assert.Equal(t, 200, resp.StatusCode)
	})

	t.Run("Login User", func(t *testing.T) {
		// First register
		reqBody := map[string]string{
			"email":    "login@example.com",
			"name":     "Login User",
			"password": "LoginPass123!",
		}
		body, _ := json.Marshal(reqBody)
		req := httptest.NewRequest(http.MethodPost, "/api/v1/auth/register", bytes.NewBuffer(body))
		req.Header.Set(contentType, applicationJSON)
		fiberApp.Test(req)

		// Then login
		loginBody := map[string]string{
			"email":    "login@example.com",
			"password": "LoginPass123!",
		}
		loginBodyBytes, _ := json.Marshal(loginBody)
		loginReq := httptest.NewRequest(http.MethodPost, "/api/v1/auth/login", bytes.NewBuffer(loginBodyBytes))
		loginReq.Header.Set(contentType, applicationJSON)
		loginResp, err := fiberApp.Test(loginReq)
		require.NoError(t, err)
		assert.Equal(t, 200, loginResp.StatusCode)
	})
}

func TestJWTService(t *testing.T) {
	logger, _ := zap.NewDevelopment()
	zapLogger := logger.Sugar()

	jwtService, err := auth.NewJWTService(auth.JWTConfig{
		SecretKey:     "test-secret-key-minimum-32-characters-long",
		AccessExpiry:  15 * 60,
		RefreshExpiry: 7 * 24 * 3600,
		Logger:        zapLogger,
	})
	require.NoError(t, err)

	t.Run("Generate and Validate Access Token", func(t *testing.T) {
		token, err := jwtService.GenerateAccessToken(testUserID, testEmail, []string{"user"})
		require.NoError(t, err)
		assert.NotEmpty(t, token)

		claims, err := jwtService.ValidateAccessToken(token)
		require.NoError(t, err)
		assert.Equal(t, testUserID, claims.UserID)
		assert.Equal(t, testEmail, claims.Email)
		assert.Equal(t, "access", claims.TokenType)
	})

	t.Run("Generate and Validate Refresh Token", func(t *testing.T) {
		token, err := jwtService.GenerateRefreshToken(testUserID, testEmail, []string{"user"})
		require.NoError(t, err)
		assert.NotEmpty(t, token)

		claims, err := jwtService.ValidateRefreshToken(token)
		require.NoError(t, err)
		assert.Equal(t, testUserID, claims.UserID)
		assert.Equal(t, "refresh", claims.TokenType)
	})
}
