package middleware

import (
	"github.com/gofiber/fiber/v2"
	"github.com/gofiber/fiber/v2/middleware/csrf"
)

// CSRFConfig holds CSRF protection configuration
type CSRFConfig struct {
	KeyLookup      string // Format: "header:name" or "form:name" or "query:name" or "param:name" or "cookie:name"
	CookieName     string
	CookieSameSite string // "strict", "lax", "none"
	Expiration     int    // Cookie expiration in seconds
}

// DefaultCSRFConfig returns default CSRF configuration
func DefaultCSRFConfig() CSRFConfig {
	return CSRFConfig{
		KeyLookup:      "header:X-CSRF-Token",
		CookieName:     "_csrf",
		CookieSameSite: "strict",
		Expiration:     3600, // 1 hour
	}
}

// CSRFProtection creates a CSRF protection middleware
func CSRFProtection(config CSRFConfig) fiber.Handler {
	csrfConfig := csrf.Config{
		KeyLookup: config.KeyLookup,
		Cookie: &fiber.Cookie{
			Name:     config.CookieName,
			SameSite: config.CookieSameSite,
			HTTPOnly: true,
			Secure:   true, // Set to false in development if needed
		},
		ContextKey: "csrf",
		ErrorHandler: func(c *fiber.Ctx, err error) error {
			return c.Status(fiber.StatusForbidden).JSON(fiber.Map{
				"error": "CSRF token validation failed",
				"message": "Invalid or missing CSRF token",
			})
		},
	}

	return csrf.New(csrfConfig)
}
