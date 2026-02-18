package middleware

import (
	"time"

	"github.com/gofiber/fiber/v2"
	"github.com/gofiber/fiber/v2/middleware/limiter"
)

// RateLimitConfig holds rate limiting configuration
type RateLimitConfig struct {
	Max        int           // Maximum requests
	Expiration time.Duration // Time window
	SkipFailed bool          // Skip failed requests
	SkipSuccess bool         // Skip successful requests
}

// DefaultRateLimitConfig returns default rate limit configuration
func DefaultRateLimitConfig() RateLimitConfig {
	return RateLimitConfig{
		Max:        100,              // 100 requests
		Expiration: 1 * time.Minute,  // per minute
		SkipFailed: false,
		SkipSuccess: false,
	}
}

// RateLimit creates a rate limiting middleware
func RateLimit(config RateLimitConfig) fiber.Handler {
	limiterConfig := limiter.Config{
		Max:        config.Max,
		Expiration: config.Expiration,
		KeyGenerator: func(c *fiber.Ctx) string {
			// Use IP address as key, or user ID if authenticated
			if userID := c.Locals("userID"); userID != nil {
				return userID.(string)
			}
			return c.IP()
		},
		LimitReached: func(c *fiber.Ctx) error {
			return c.Status(fiber.StatusTooManyRequests).JSON(fiber.Map{
				"error": "Too many requests",
				"message": "Rate limit exceeded. Please try again later.",
			})
		},
		SkipFailedRequests: config.SkipFailed,
		SkipSuccessfulRequests: config.SkipSuccess,
		// Storage will use in-memory by default
		// For production, use Redis: limiter.New(limiter.Config{Storage: redis.New(...)})
	}

	return limiter.New(limiterConfig)
}

// StrictRateLimit creates a stricter rate limit (10 requests per minute)
func StrictRateLimit() fiber.Handler {
	return RateLimit(RateLimitConfig{
		Max:        10,
		Expiration: 1 * time.Minute,
	})
}

// AuthRateLimit creates a rate limit for authentication endpoints (5 requests per minute)
func AuthRateLimit() fiber.Handler {
	return RateLimit(RateLimitConfig{
		Max:        5,
		Expiration: 1 * time.Minute,
	})
}
