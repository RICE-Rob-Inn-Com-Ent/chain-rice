package docs

import (
	"github.com/gofiber/fiber/v2"
	swagger "github.com/swaggo/fiber-swagger"
)

// SetupSwagger sets up Swagger documentation
func SetupSwagger(app *fiber.App, basePath string) {
	// Swagger route - WrapHandler is the default handler
	app.Get("/swagger/*", swagger.WrapHandler)
}

// @title Rice Backend API
// @version 1.0.0
// @description This is the Rice Backend API documentation
// @termsOfService http://swagger.io/terms/

// @contact.name API Support
// @contact.email support@rice.com

// @license.name MIT
// @license.url https://opensource.org/licenses/MIT

// @host localhost:8080
// @BasePath /api/v1

// @securityDefinitions.apikey BearerAuth
// @in header
// @name Authorization
// @description Type "Bearer" followed by a space and JWT token.
