package middleware

import (
	"strings"

	"github.com/gofiber/fiber/v2"
	"github.com/chainrice/rice/backend/app/auth"
)

// JWTAuth creates JWT authentication middleware
func JWTAuth(jwtService *auth.JWTService) fiber.Handler {
	return func(c *fiber.Ctx) error {
		authHeader := c.Get("Authorization")
		if authHeader == "" {
			return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{
				"error": "Missing Authorization header",
			})
		}

		// Extract token from "Bearer <token>" format
		parts := strings.Split(authHeader, " ")
		if len(parts) != 2 || parts[0] != "Bearer" {
			return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{
				"error": "Invalid Authorization header format. Expected: Bearer <token>",
			})
		}

		token := strings.TrimSpace(parts[1])
		if token == "" {
			return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{
				"error": "Token is required",
			})
		}

		// Validate token
		claims, err := jwtService.ValidateAccessToken(token)
		if err != nil {
			return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{
				"error": "Invalid or expired token",
				"details": err.Error(),
			})
		}

		// Store claims in context
		c.Locals("userID", claims.UserID)
		c.Locals("email", claims.Email)
		c.Locals("roles", claims.Roles)
		c.Locals("token", token)

		return c.Next()
	}
}

// RequireRole creates middleware that requires specific roles
func RequireRole(roles ...string) fiber.Handler {
	return func(c *fiber.Ctx) error {
		userRoles, ok := c.Locals("roles").([]string)
		if !ok {
			return c.Status(fiber.StatusForbidden).JSON(fiber.Map{
				"error": "Access denied",
			})
		}

		// Check if user has any of the required roles
		hasRole := false
		for _, requiredRole := range roles {
			for _, userRole := range userRoles {
				if userRole == requiredRole {
					hasRole = true
					break
				}
			}
			if hasRole {
				break
			}
		}

		if !hasRole {
			return c.Status(fiber.StatusForbidden).JSON(fiber.Map{
				"error": "Insufficient permissions",
				"message": "You don't have the required role to access this resource",
			})
		}

		return c.Next()
	}
}
