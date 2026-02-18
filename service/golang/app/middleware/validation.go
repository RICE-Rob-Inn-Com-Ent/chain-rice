package middleware

import (
	"github.com/go-playground/validator/v10"
	"github.com/gofiber/fiber/v2"
)

var validate *validator.Validate

func init() {
	validate = validator.New()
}

// ValidateRequest validates request body against struct tags
func ValidateRequest(dest interface{}) fiber.Handler {
	return func(c *fiber.Ctx) error {
		if err := c.BodyParser(dest); err != nil {
			return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
				"error": "Invalid request body",
				"details": err.Error(),
			})
		}

		if err := validate.Struct(dest); err != nil {
			errors := make(map[string]string)
			for _, err := range err.(validator.ValidationErrors) {
				field := err.Field()
				tag := err.Tag()
				errors[field] = getValidationErrorMessage(field, tag)
			}

			return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
				"error": "Validation failed",
				"details": errors,
			})
		}

		// Store validated data in context
		c.Locals("validated", dest)
		return c.Next()
	}
}

// ValidateQuery validates query parameters
func ValidateQuery(dest interface{}) fiber.Handler {
	return func(c *fiber.Ctx) error {
		if err := c.QueryParser(dest); err != nil {
			return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
				"error": "Invalid query parameters",
				"details": err.Error(),
			})
		}

		if err := validate.Struct(dest); err != nil {
			errors := make(map[string]string)
			for _, err := range err.(validator.ValidationErrors) {
				field := err.Field()
				tag := err.Tag()
				errors[field] = getValidationErrorMessage(field, tag)
			}

			return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
				"error": "Validation failed",
				"details": errors,
			})
		}

		c.Locals("validated", dest)
		return c.Next()
	}
}

// ValidateParams validates route parameters
func ValidateParams(dest interface{}) fiber.Handler {
	return func(c *fiber.Ctx) error {
		if err := c.ParamsParser(dest); err != nil {
			return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
				"error": "Invalid route parameters",
				"details": err.Error(),
			})
		}

		if err := validate.Struct(dest); err != nil {
			errors := make(map[string]string)
			for _, err := range err.(validator.ValidationErrors) {
				field := err.Field()
				tag := err.Tag()
				errors[field] = getValidationErrorMessage(field, tag)
			}

			return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
				"error": "Validation failed",
				"details": errors,
			})
		}

		c.Locals("validated", dest)
		return c.Next()
	}
}

func getValidationErrorMessage(field, tag string) string {
	switch tag {
	case "required":
		return field + " is required"
	case "email":
		return field + " must be a valid email address"
	case "min":
		return field + " is too short"
	case "max":
		return field + " is too long"
	case "uuid":
		return field + " must be a valid UUID"
	case "url":
		return field + " must be a valid URL"
	default:
		return field + " is invalid"
	}
}
