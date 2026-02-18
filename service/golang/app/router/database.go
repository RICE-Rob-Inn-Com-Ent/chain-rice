package router

import (
	"fmt"
	"net"
	"net/http"
	"time"

	"github.com/gofiber/fiber/v2"

	"github.com/chainrice/rice/backend/app/helpers"
)

// RunDatabaseRouter starts the database router service
func RunDatabaseRouter() {
	postgresHost := helpers.GetEnv("POSTGRES_HOST", "devcontainer-postgres")
	postgresPort := helpers.GetEnv("POSTGRES_PORT", "5432")
	mongodbHost := helpers.GetEnv("MONGODB_HOST", "devcontainer-mongodb")
	mongodbPort := helpers.GetEnv("MONGODB_PORT", "27017")
	redisHost := helpers.GetEnv("REDIS_HOST", "devcontainer-redis")
	redisPort := helpers.GetEnv("REDIS_PORT", "6379")

	cfg := Config{
		Name:        "Database Router",
		Port:        "8084",
		ServiceName: "database-router",
		HealthCheck: func(client *http.Client) map[string]interface{} {
			return map[string]interface{}{
				"postgres": map[string]interface{}{
					"healthy": checkTCPConnection(postgresHost, postgresPort),
					"host":    postgresHost,
					"port":    postgresPort,
				},
				"mongodb": map[string]interface{}{
					"healthy": checkTCPConnection(mongodbHost, mongodbPort),
					"host":    mongodbHost,
					"port":    mongodbPort,
				},
				"redis": map[string]interface{}{
					"healthy": checkTCPConnection(redisHost, redisPort),
					"host":    redisHost,
					"port":    redisPort,
				},
			}
		},
		Routes: func(fiberApp *fiber.App) {
			fiberApp.Get("/databases", func(c *fiber.Ctx) error {
				return c.JSON(fiber.Map{
					"postgres": fiber.Map{
						"type":     "relational",
						"host":     postgresHost,
						"port":     postgresPort,
						"endpoint": fmt.Sprintf("%s:%s", postgresHost, postgresPort),
					},
					"mongodb": fiber.Map{
						"type":     "document",
						"host":     mongodbHost,
						"port":     mongodbPort,
						"endpoint": fmt.Sprintf("%s:%s", mongodbHost, mongodbPort),
					},
					"redis": fiber.Map{
						"type":     "cache",
						"host":     redisHost,
						"port":     redisPort,
						"endpoint": fmt.Sprintf("%s:%s", redisHost, redisPort),
					},
				})
			})
		},
	}

	New(cfg)
}

// checkTCPConnection checks if a TCP connection can be established
func checkTCPConnection(host, port string) bool {
	timeout := 2 * time.Second
	conn, err := net.DialTimeout("tcp", net.JoinHostPort(host, port), timeout)
	if err != nil {
		return false
	}
	conn.Close()
	return true
}
