package router

import (
	"net/http"

	"github.com/gofiber/fiber/v2"
	"github.com/gofiber/fiber/v2/middleware/proxy"

	"github.com/chainrice/rice/backend/app/helpers"
)

// RunMonitoringRouter starts the monitoring router service
func RunMonitoringRouter() {
	prometheusURL := helpers.GetEnv("PROMETHEUS_URL", "http://devcontainer-prometheus:9090")
	grafanaURL := helpers.GetEnv("GRAFANA_URL", "http://devcontainer-grafana:3000")
	jaegerURL := helpers.GetEnv("JAEGER_URL", "http://devcontainer-jaeger:16686")

	cfg := Config{
		Name:        "Monitoring Router",
		Port:        "8083",
		ServiceName: "monitoring-router",
		HealthCheck: func(client *http.Client) map[string]interface{} {
			return map[string]interface{}{
				"prometheus": map[string]interface{}{
					"healthy": CheckHealth(client, prometheusURL+"/-/healthy"),
					"url":     prometheusURL,
				},
				"grafana": map[string]interface{}{
					"healthy": CheckHealth(client, grafanaURL+"/api/health"),
					"url":     grafanaURL,
				},
				"jaeger": map[string]interface{}{
					"healthy": CheckHealth(client, jaegerURL+"/"),
					"url":     jaegerURL,
				},
			}
		},
		Routes: func(fiberApp *fiber.App) {
			fiberApp.All("/prometheus/*", func(c *fiber.Ctx) error {
				return proxy.Forward(prometheusURL + c.Path()[12:])(c)
			})
			fiberApp.All("/grafana/*", func(c *fiber.Ctx) error {
				return proxy.Forward(grafanaURL + c.Path()[8:])(c)
			})
			fiberApp.All("/jaeger/*", func(c *fiber.Ctx) error {
				return proxy.Forward(jaegerURL + c.Path()[7:])(c)
			})
		},
	}

	New(cfg)
}
