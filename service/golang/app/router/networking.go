package router

import (
	"io"
	"net/http"
	"time"

	"github.com/gofiber/fiber/v2"
	"github.com/gofiber/fiber/v2/middleware/proxy"

	"github.com/chainrice/rice/backend/app/helpers"
)

// RunTraefikProxy starts the Traefik proxy router service
func RunTraefikProxy() {
	traefikURL := helpers.GetEnv("TRAEFIK_URL", "http://devcontainer-traefik:8080")
	traefikWebURL := helpers.GetEnv("TRAEFIK_WEB_URL", "http://devcontainer-traefik:80")
	traefikWebSecureURL := helpers.GetEnv("TRAEFIK_WEBSECURE_URL", "http://devcontainer-traefik:443")
	traefikMetricsURL := helpers.GetEnv("TRAEFIK_METRICS_URL", "http://devcontainer-traefik:9101")

	cfg := Config{
		Name:        "Traefik Proxy",
		Port:        "8080",
		ServiceName: "traefik-proxy",
		HealthCheck: func(client *http.Client) map[string]interface{} {
			resp, err := client.Get(traefikURL + "/api/overview")
			healthy := err == nil && resp != nil && resp.StatusCode == 200
			if resp != nil {
				resp.Body.Close()
			}
			return map[string]interface{}{
				"traefik": map[string]interface{}{
					"healthy": healthy,
					"url":     traefikURL,
				},
			}
		},
		Routes: func(fiberApp *fiber.App) {
			fiberApp.All("/api/*", func(c *fiber.Ctx) error {
				return proxy.Forward(traefikURL + c.Path())(c)
			})
			fiberApp.All("/web/*", func(c *fiber.Ctx) error {
				return proxy.Forward(traefikWebURL + c.Path()[4:])(c)
			})
			fiberApp.All("/websecure/*", func(c *fiber.Ctx) error {
				return proxy.Forward(traefikWebSecureURL + c.Path()[11:])(c)
			})
			fiberApp.Get("/metrics", func(c *fiber.Ctx) error {
				client := &http.Client{Timeout: 10 * time.Second}
				resp, err := client.Get(traefikMetricsURL + "/metrics")
				if err != nil {
					return c.Status(503).JSON(fiber.Map{"error": "Traefik metrics unavailable"})
				}
				defer resp.Body.Close()

				body, err := io.ReadAll(resp.Body)
				if err != nil {
					return c.Status(500).JSON(fiber.Map{"error": "Failed to read metrics"})
				}

				c.Set("Content-Type", "text/plain")
				return c.Send(body)
			})
		},
	}

	New(cfg)
}

// RunElasticsearchProxy starts the Elasticsearch proxy router service
func RunElasticsearchProxy() {
	elasticsearchURL := helpers.GetEnv("ELASTICSEARCH_URL", "http://devcontainer-elasticsearch:9200")

	cfg := Config{
		Name:        "Elasticsearch Proxy",
		Port:        "8087",
		ServiceName: "elasticsearch-proxy",
		HealthCheck: func(client *http.Client) map[string]interface{} {
			resp, err := client.Get(elasticsearchURL + "/_cluster/health")
			healthy := err == nil && resp != nil && resp.StatusCode == 200
			if resp != nil {
				resp.Body.Close()
			}
			return map[string]interface{}{
				"elasticsearch": map[string]interface{}{
					"healthy": healthy,
					"url":     elasticsearchURL,
				},
			}
		},
		Routes: func(fiberApp *fiber.App) {
			fiberApp.All("/*", func(c *fiber.Ctx) error {
				return proxy.Forward(elasticsearchURL + c.Path())(c)
			})
		},
	}

	New(cfg)
}
