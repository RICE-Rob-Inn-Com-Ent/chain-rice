package main

import (
	"log"
	"net/http"
	"os"

	"github.com/gin-contrib/cors"
	"github.com/gin-gonic/gin"

	"chainrice/shared"
	"chainrice/shared/handlers"
	"chainrice/shared/services"
)

func main() {
	// Initialize database
	db, err := shared.InitDB()
	if err != nil {
		log.Fatal("Failed to initialize database:", err)
	}
	defer db.Close()

	// Initialize services
	invoiceService := services.NewInvoiceService(db)
	dashboardService := services.NewDashboardService(db)
	validatorService := services.NewValidatorService(db)

	// Start gRPC server
	go startGRPCServer(invoiceService, dashboardService)

	// Start HTTP server
	startHTTPServer(invoiceService, dashboardService, validatorService)
}

func startGRPCServer(invoiceService *services.InvoiceService, dashboardService *services.DashboardService) {
	// gRPC server implementation would go here
	// For now, we'll just log that it's starting
	log.Println("gRPC server would start here")
}

func startHTTPServer(invoiceService *services.InvoiceService, dashboardService *services.DashboardService, validatorService *services.ValidatorService) {
	// Set Gin mode
	if os.Getenv("GIN_MODE") == "release" {
		gin.SetMode(gin.ReleaseMode)
	}

	// Create Gin router
	router := gin.Default()

	// Add CORS middleware
	config := cors.DefaultConfig()
	config.AllowOrigins = []string{
		"http://localhost:5173",
		"http://localhost:3000",
	}
	config.AllowMethods = []string{"GET", "POST", "PUT", "DELETE", "OPTIONS"}
	config.AllowHeaders = []string{"*"}
	router.Use(cors.New(config))

	// Health check endpoint
	router.GET("/health", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{
			"service": "accounting-api",
			"status":  "healthy",
		})
	})

	// API routes
	api := router.Group("/api/v1")
	{
		// Dashboard routes
		api.GET("/dashboard/stats", handlers.GetDashboardStats(dashboardService))

		// Invoice routes
		api.GET("/invoices", handlers.ListInvoices(invoiceService))
		api.POST("/invoices", handlers.CreateInvoice(invoiceService))
		api.GET("/invoices/:id", handlers.GetInvoice(invoiceService))
		api.PUT("/invoices/:id", handlers.UpdateInvoice(invoiceService))
		api.DELETE("/invoices/:id", handlers.DeleteInvoice(invoiceService))

		// File upload routes
		api.POST("/upload", handlers.UploadFile())
		api.POST("/receipts/process", handlers.ProcessReceipt(invoiceService))

		// Validator routes
		api.GET("/validators", handlers.GetValidators(validatorService))
		api.GET("/validators/:id", handlers.GetValidator(validatorService))
		api.GET("/validators/stats", handlers.GetValidatorStats(validatorService))
		api.GET("/validators/bitcoin-balances", handlers.GetBitcoinBalances(validatorService))
		api.GET("/validators/:id/performance", handlers.GetValidatorPerformance(validatorService))
		api.PUT("/validators/:id/performance", handlers.UpdateValidatorPerformance(validatorService))
		api.PUT("/validators/bitcoin-balance", handlers.UpdateBitcoinBalance(validatorService))
		api.GET("/network/health", handlers.GetNetworkHealth(validatorService))
		api.POST("/network/refresh", handlers.RefreshNetworkData(validatorService))
	}

	// Get port from environment or use default
	port := os.Getenv("PORT")
	if port == "" {
		port = "8002"
	}

	log.Printf("Accounting API server starting on port %s", port)
	log.Fatal(router.Run(":" + port))
}
