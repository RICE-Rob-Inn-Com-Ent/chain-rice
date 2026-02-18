package router

import (
	"net/http"

	"github.com/gofiber/fiber/v2"
	"github.com/gofiber/fiber/v2/middleware/proxy"

	"github.com/chainrice/rice/backend/app/helpers"
)

// RunAdminRouter starts the admin router service
func RunAdminRouter() {
	pgadminURL := helpers.GetEnv("PGADMIN_URL", "http://devcontainer-pgadmin:80")
	mongoExpressURL := helpers.GetEnv("MONGO_EXPRESS_URL", "http://devcontainer-mongo-express:8081")
	redisCommanderURL := helpers.GetEnv("REDIS_COMMANDER_URL", "http://devcontainer-redis-commander:8081")

	cfg := Config{
		Name:        "Admin Router",
		Port:        "8085",
		ServiceName: "admin-router",
		HealthCheck: func(client *http.Client) map[string]interface{} {
			return map[string]interface{}{
				"pgadmin": map[string]interface{}{
					"healthy": CheckHealth(client, pgadminURL),
					"url":     pgadminURL,
				},
				"mongo_express": map[string]interface{}{
					"healthy": CheckHealth(client, mongoExpressURL),
					"url":     mongoExpressURL,
				},
				"redis_commander": map[string]interface{}{
					"healthy": CheckHealth(client, redisCommanderURL),
					"url":     redisCommanderURL,
				},
			}
		},
		Routes: func(fiberApp *fiber.App) {
			fiberApp.All("/pgadmin/*", func(c *fiber.Ctx) error {
				return proxy.Forward(pgadminURL + c.Path()[8:])(c)
			})
			fiberApp.All("/mongo-express/*", func(c *fiber.Ctx) error {
				return proxy.Forward(mongoExpressURL + c.Path()[15:])(c)
			})
			fiberApp.All("/redis-commander/*", func(c *fiber.Ctx) error {
				return proxy.Forward(redisCommanderURL + c.Path()[17:])(c)
			})
		},
	}

	New(cfg)
}
